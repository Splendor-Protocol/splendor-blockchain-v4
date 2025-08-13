// Copyright 2017 The go-ethereum Authors
// This file is part of the go-ethereum library.
//
// The go-ethereum library is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// The go-ethereum library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with the go-ethereum library. If not, see <http://www.gnu.org/licenses/>.

package congress

import (
	"bytes"
	"encoding/json"
	"math"
	"sort"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/consensus"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/ethdb"
	"github.com/ethereum/go-ethereum/log"
	"github.com/ethereum/go-ethereum/params"
	lru "github.com/hashicorp/golang-lru"
)

// Snapshot is the state of the authorization voting at a given point in time.
type Snapshot struct {
	config   *params.CongressConfig // Consensus engine parameters to fine tune behavior
	sigcache *lru.ARCCache          // Cache of recent block signatures to speed up ecrecover

	Number     uint64                      `json:"number"`     // Block number where the snapshot was created
	Hash       common.Hash                 `json:"hash"`       // Block hash where the snapshot was created
	Validators map[common.Address]struct{} `json:"validators"` // Set of authorized validators at this moment
	Recents    map[uint64]common.Address   `json:"recents"`    // Set of recent validators for spam protections
}

// validatorsAscending implements the sort interface to allow sorting a list of addresses
type validatorsAscending []common.Address

func (s validatorsAscending) Len() int           { return len(s) }
func (s validatorsAscending) Less(i, j int) bool { return bytes.Compare(s[i][:], s[j][:]) < 0 }
func (s validatorsAscending) Swap(i, j int)      { s[i], s[j] = s[j], s[i] }

// newSnapshot creates a new snapshot with the specified startup parameters. This
// method does not initialize the set of recent validators, so only ever use if for
// the genesis block.
func newSnapshot(config *params.CongressConfig, sigcache *lru.ARCCache, number uint64, hash common.Hash, validators []common.Address) *Snapshot {
	snap := &Snapshot{
		config:     config,
		sigcache:   sigcache,
		Number:     number,
		Hash:       hash,
		Validators: make(map[common.Address]struct{}),
		Recents:    make(map[uint64]common.Address),
	}
	for _, validator := range validators {
		snap.Validators[validator] = struct{}{}
	}
	return snap
}

// loadSnapshot loads an existing snapshot from the database.
func loadSnapshot(config *params.CongressConfig, sigcache *lru.ARCCache, db ethdb.Database, hash common.Hash) (*Snapshot, error) {
	blob, err := db.Get(append([]byte("congress-"), hash[:]...))
	if err != nil {
		return nil, err
	}
	snap := new(Snapshot)
	if err := json.Unmarshal(blob, snap); err != nil {
		return nil, err
	}
	snap.config = config
	snap.sigcache = sigcache

	return snap, nil
}

// store inserts the snapshot into the database.
func (s *Snapshot) store(db ethdb.Database) error {
	blob, err := json.Marshal(s)
	if err != nil {
		return err
	}
	return db.Put(append([]byte("congress-"), s.Hash[:]...), blob)
}

// copy creates a deep copy of the snapshot, though not the individual votes.
func (s *Snapshot) copy() *Snapshot {
	cpy := &Snapshot{
		config:     s.config,
		sigcache:   s.sigcache,
		Number:     s.Number,
		Hash:       s.Hash,
		Validators: make(map[common.Address]struct{}),
		Recents:    make(map[uint64]common.Address),
	}
	for validator := range s.Validators {
		cpy.Validators[validator] = struct{}{}
	}
	for block, validator := range s.Recents {
		cpy.Recents[block] = validator
	}

	return cpy
}

// apply creates a new authorization snapshot by applying the given headers to
// the original one.
func (s *Snapshot) apply(headers []*types.Header, chain consensus.ChainHeaderReader, parents []*types.Header) (*Snapshot, error) {
	// Allow passing in no headers for cleaner code
	if len(headers) == 0 {
		return s, nil
	}
	// Sanity check that the headers can be applied
	for i := 0; i < len(headers)-1; i++ {
		if headers[i+1].Number.Uint64() != headers[i].Number.Uint64()+1 {
			return nil, errInvalidVotingChain
		}
	}
	if headers[0].Number.Uint64() != s.Number+1 {
		return nil, errInvalidVotingChain
	}
	// Iterate through the headers and create a new snapshot
	snap := s.copy()

	for _, header := range headers {
		// Remove any votes on checkpoint blocks
		number := header.Number.Uint64()
		// Delete the oldest validator from the recent list to allow it signing again
		if limit := uint64(len(snap.Validators)/2 + 1); number >= limit {
			delete(snap.Recents, number-limit)
		}
		// Resolve the authorization key and check against validators
		validator, err := ecrecover(header, s.sigcache)
		if err != nil {
			return nil, err
		}
		if _, ok := snap.Validators[validator]; !ok {
			return nil, errUnauthorizedValidator
		}
		for _, recent := range snap.Recents {
			if recent == validator {
				return nil, errRecentlySigned
			}
		}
		snap.Recents[number] = validator

		// update validators at the first block at epoch
		if number > 0 && number%s.config.Epoch == 0 {
			checkpointHeader := header

			// get validators from headers and use that for new validator set
			validators := make([]common.Address, (len(checkpointHeader.Extra)-extraVanity-extraSeal)/common.AddressLength)
			for i := 0; i < len(validators); i++ {
				copy(validators[i][:], checkpointHeader.Extra[extraVanity+i*common.AddressLength:])
			}

			newValidators := make(map[common.Address]struct{})
			for _, validator := range validators {
				newValidators[validator] = struct{}{}
			}

			// ENHANCED BYZANTINE FAULT TOLERANCE: Clean up recent validators when validator set changes
			// This handles validator addition, removal, and replacement cases to prevent chain halt
			oldValidatorCount := len(snap.Validators)
			newValidatorCount := len(newValidators)
			
			// Calculate new limit for recent validators
			newLimit := uint64(newValidatorCount/2 + 1)
			oldLimit := uint64(oldValidatorCount/2 + 1)
			
			log.Info("Validator set change detected at epoch", 
				"oldCount", oldValidatorCount, "newCount", newValidatorCount, 
				"oldLimit", oldLimit, "newLimit", newLimit, "recentCount", len(snap.Recents))
			
			// CRITICAL FIX 1: Aggressive cleanup for validator set expansion
			if newValidatorCount > oldValidatorCount {
				log.Info("Validator set expanding - applying aggressive recent cleanup")
				
				// Clear ALL recent entries that are older than the new limit
				// This is more aggressive than the original fix to prevent deadlock
				for blockNum := range snap.Recents {
					if number >= newLimit && blockNum <= number-newLimit {
						delete(snap.Recents, blockNum)
						log.Debug("Cleared recent entry for expansion", "blockNum", blockNum)
					}
				}
				
				// Additional safety: if still too many recents after cleanup, clear oldest entries
				if len(snap.Recents) >= newValidatorCount {
					log.Warn("Still too many recent validators after expansion cleanup, clearing oldest")
					
					// Find and remove the oldest entries until we have room
					for len(snap.Recents) >= newValidatorCount {
						oldestBlock := uint64(math.MaxUint64)
						for blockNum := range snap.Recents {
							if blockNum < oldestBlock {
								oldestBlock = blockNum
							}
						}
						delete(snap.Recents, oldestBlock)
						log.Debug("Emergency cleared oldest recent entry", "blockNum", oldestBlock)
					}
				}
				
			} else if newValidatorCount < oldValidatorCount {
				// CRITICAL FIX 2: Enhanced cleanup for validator set reduction
				log.Info("Validator set reducing - applying enhanced recent cleanup")
				
				// Clear entries based on the difference in validator counts
				entriesToClear := oldValidatorCount/2 - newValidatorCount/2
				if entriesToClear > 0 {
					for i := 0; i < entriesToClear; i++ {
						targetBlock := number - oldLimit - uint64(i)
						if _, exists := snap.Recents[targetBlock]; exists {
							delete(snap.Recents, targetBlock)
							log.Debug("Cleared recent entry for reduction", "blockNum", targetBlock)
						}
					}
				}
				
				// Additional cleanup for any entries beyond the new limit
				for blockNum := range snap.Recents {
					if number >= newLimit && blockNum <= number-newLimit {
						delete(snap.Recents, blockNum)
						log.Debug("Additional cleanup for reduction", "blockNum", blockNum)
					}
				}
				
			} else {
				// CRITICAL FIX 3: Enhanced cleanup for same validator count (validator replacement)
				log.Info("Validator set same size - checking for validator replacement")
				
				// Check if validators actually changed (replacement scenario)
				validatorsChanged := false
				for newValidator := range newValidators {
					if _, exists := snap.Validators[newValidator]; !exists {
						validatorsChanged = true
						break
					}
				}
				
				if validatorsChanged {
					log.Info("Validator replacement detected - applying cleanup")
					
					// Clear recent entries for replaced validators
					validatorsToRemove := make([]uint64, 0)
					for blockNum, recentValidator := range snap.Recents {
						if _, stillValidator := newValidators[recentValidator]; !stillValidator {
							validatorsToRemove = append(validatorsToRemove, blockNum)
						}
					}
					
					for _, blockNum := range validatorsToRemove {
						delete(snap.Recents, blockNum)
						log.Debug("Cleared recent entry for replaced validator", "blockNum", blockNum)
					}
				}
				
				// Standard cleanup for old entries
				for blockNum := range snap.Recents {
					if number >= newLimit && blockNum <= number-newLimit {
						delete(snap.Recents, blockNum)
						log.Debug("Standard cleanup", "blockNum", blockNum)
					}
				}
			}
			
			// CRITICAL FIX 4: Emergency deadlock prevention
			// If we still have too many recent validators after all cleanup, force clear oldest
			if len(snap.Recents) >= newValidatorCount {
				log.Error("EMERGENCY: Too many recent validators after cleanup - forcing clear", 
					"recentCount", len(snap.Recents), "validatorCount", newValidatorCount)
				
				// Keep clearing oldest entries until we have breathing room
				targetRecentCount := (newValidatorCount * 2) / 3 // Keep it at 2/3 of validator count
				
				for len(snap.Recents) > targetRecentCount {
					oldestBlock := uint64(math.MaxUint64)
					for blockNum := range snap.Recents {
						if blockNum < oldestBlock {
							oldestBlock = blockNum
						}
					}
					delete(snap.Recents, oldestBlock)
					log.Warn("Emergency cleared recent validator", "blockNum", oldestBlock, 
						"remainingRecents", len(snap.Recents), "target", targetRecentCount)
				}
			}
			
			log.Info("Validator set cleanup completed", 
				"finalRecentCount", len(snap.Recents), "validatorCount", newValidatorCount)

			snap.Validators = newValidators
		}
	}

	snap.Number += uint64(len(headers))
	snap.Hash = headers[len(headers)-1].Hash()

	return snap, nil
}

// validators retrieves the list of authorized validators in ascending order.
func (s *Snapshot) validators() []common.Address {
	sigs := make([]common.Address, 0, len(s.Validators))
	for sig := range s.Validators {
		sigs = append(sigs, sig)
	}
	sort.Sort(validatorsAscending(sigs))
	return sigs
}

// inturn returns if a validator at a given block height is in-turn or not.
func (s *Snapshot) inturn(number uint64, validator common.Address) bool {
	validators, offset := s.validators(), 0
	for offset < len(validators) && validators[offset] != validator {
		offset++
	}
	return (number % uint64(len(validators))) == uint64(offset)
}
