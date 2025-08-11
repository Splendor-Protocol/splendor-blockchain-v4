# Splendor RPC System Contracts
This repository hosts system smart contracts of the Splendor RPC Chain

# Consensus
`Splendor RPC` adopts `DPoS` consensus mechanism with low transaction cost, low transaction latency, high transaction concurrency, and supports up to 10,000 validators.

DPoS allows anyone to become a validator by staking specified coins. It also allows delegators to stake small amounts and to participate in network security. Any address can stake to an address that qualifies to become a validator, and after the validator's staking volume ranks in the top validators, it will become an active validator in the next epoch.

All active validators are ordered according to predefined rules and take turns to pack out blocks. If a validator fails to pack out a block in time in its own round, the active validators who have not been involved in the past n/2 (n is the number of active validators) blocks will randomly perform the block-out. At least n/2+1 active validators work properly to ensure the proper operation of the blockchain.

The difficulty value of a block is 2 when the block is generated normally and 1 when the block is not generated in a predefined order. When a fork of the blockchain occurs, the blockchain selects the corresponding fork according to the cumulative maximum difficulty.

## Validator Tiers

Splendor RPC implements a three-tier validator system based on staking amounts:

### Bronze Tier (Entry Level)
- **Minimum Stake:** 3,947 SPLD (~$1,500)
- **Target:** New validators and smaller participants
- **Benefits:** Basic validator rewards and network participation

### Silver Tier (Mid Level)
- **Minimum Stake:** 39,474 SPLD (~$15,000)
- **Target:** Committed validators with higher investment
- **Benefits:** Enhanced network influence and rewards

### Gold Tier (Premium Level)
- **Minimum Stake:** 394,737 SPLD (~$150,000)
- **Target:** Major validators and institutional participants
- **Benefits:** Maximum network influence and premium rewards

**Automatic Tier Management:** Validator tiers are automatically assigned and updated based on total staking amount (including delegated stakes). When additional staking occurs, validator tiers are dynamically updated to reflect the new staking level.

## Fee Distribution

Splendor RPC uses a transparent and fair fee distribution model:

- **60%** to Validators (they invest in and run infrastructure)
- **30%** to Stakers (passive participation through delegation)
- **10%** to Protocol Development (ongoing blockchain improvements)

**No Burning:** Unlike many other blockchains, Splendor RPC does not burn any tokens, ensuring all fees contribute to network security and development.

## Glossary 
- **validator:** Responsible for packaging out blocks for on-chain transactions.
- **active validator:** The current set of validators responsible for packing out blocks, with a maximum of 10,000.
- **epoch:** Time interval in blocks, currently 1 epoch = 100 blocks on `Splendor RPC`. At the end of each epoch, the blockchain interacts with the system contracts to update active validators.
- **tier:** Classification level (Bronze/Silver/Gold) based on validator's total staking amount.
- **staker:** Users who delegate their tokens to validators to earn rewards.

The management of the current validators are all done by the system contracts:
- **Proposal:** Responsible for managing access to validators and managing validator proposals and votes.
- **Validators:** Responsible for ranking management of validators, staking and unstaking operations, distribution of block rewards, tier management, etc.
- **Punish:** Responsible for punishing operations against active validators who are not working properly.

Blockchain calls system contracts:
- At the end of each block, the `Validators` contract is called and the fees for all transactions in the block are distributed to active validators.
- The `Punish` contract is called to punish the validator when the validator is not working properly.
- At the end of each epoch, the `Validators` contract is called to update active validators, based on the ranking.

## Staking

For any account, any number of coins can be staked to the validator. The minimum staking amounts are:
- **Bronze Tier:** 3,947 SPLD minimum
- **Silver Tier:** 39,474 SPLD minimum  
- **Gold Tier:** 394,737 SPLD minimum

### Staking Process:
1. Choose a validator to stake to
2. Send staking transaction with desired amount
3. Validator tier is automatically updated based on total staking
4. Start earning rewards immediately

### Unstaking Process:
If you want to unstake, you need to do the following:
1. Send an unstaking transaction for a validator to the `Validators` contract
2. Wait for `86400` blocks (staking lock period) before sending a transaction to `Validators` contract to withdraw all staking coins on this validator

### Reward Withdrawal:
Stakers can withdraw their accumulated rewards at any time by calling the `withdrawStakingReward` function.

## Validator Creation

To become a validator:
1. Ensure you have the minimum staking amount (3,947 SPLD for Bronze tier)
2. Call `createOrEditValidator` with:
   - `feeAddr`: Address to receive validator rewards
   - `moniker`: Validator name (max 70 characters)
3. Your validator tier will be automatically assigned based on staking amount
4. Start participating in block production and earning rewards

## Punishment

Whenever a validator is found not to pack blocks as predefined, the `Punish` contract is automatically called at the end of this block and the validator is counted. When the count reaches the punishment threshold:
- Validator income may be redistributed to other active validators
- Validator may be temporarily jailed
- In severe cases, validator may be removed from the active set

## Contract Addresses

- **Validators Contract:** `0x000000000000000000000000000000000000f000`
- **Punish Contract:** `0x000000000000000000000000000000000000F001`
- **Proposal Contract:** `0x000000000000000000000000000000000000F002`
- **Slashing Contract:** `0x000000000000000000000000000000000000F007`

## Key Features

- **Tiered System:** Three-tier validator classification for fair participation
- **Dynamic Updates:** Automatic tier updates based on staking changes
- **Fair Distribution:** Transparent fee distribution to validators, stakers, and development
- **No Burning:** All fees contribute to network participants and development
- **Scalable:** Supports up to 10,000 validators
- **Efficient:** Fast block times with DPoS consensus
- **Secure:** Robust punishment system for misbehaving validators
