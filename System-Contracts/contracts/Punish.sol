// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Params.sol";
import "./Validators.sol";

contract Punish is Params {
    uint256 public punishThreshold;
    uint256 public removeThreshold;
    uint256 public decreaseRate;
    
    // SECURITY FIX: Add maximum validators to process per transaction to prevent gas limit attacks
    uint256 public constant MAX_VALIDATORS_PER_TX = 50;

    struct PunishRecord {
        uint256 missedBlocksCounter;
        uint256 index;
        bool exist;
    }

    Validators validators;

    mapping(address => PunishRecord) punishRecords;
    address[] public punishValidators;

    mapping(uint256 => bool) punished;
    mapping(uint256 => bool) decreased;

    event LogDecreaseMissedBlocksCounter();
    event LogPunishValidator(address indexed val, uint256 time);

    modifier onlyNotPunished() {
        require(!punished[block.number], "Already punished");
        _;
    }

    modifier onlyNotDecreased() {
        require(!decreased[block.number], "Already decreased");
        _;
    }

    function initialize() external onlyNotInitialized {
        validators = Validators(ValidatorContractAddr);
        punishThreshold = 48;
        removeThreshold = 96;
        decreaseRate = 48;

        initialized = true;
    }

    function punish(address val)
        external
        onlyMiner
        onlyInitialized
        onlyNotPunished
    {
        // SECURITY FIX: Update state BEFORE external calls
        punished[block.number] = true;
        if (!punishRecords[val].exist) {
            punishRecords[val].index = punishValidators.length;
            punishValidators.push(val);
            punishRecords[val].exist = true;
        }
        punishRecords[val].missedBlocksCounter++;

        // Store values for external calls
        bool shouldRemove = punishRecords[val].missedBlocksCounter % removeThreshold == 0;
        bool shouldRemoveIncoming = punishRecords[val].missedBlocksCounter % punishThreshold == 0;

        // Update state before external calls
        if (shouldRemove) {
            // reset validator's missed blocks counter
            punishRecords[val].missedBlocksCounter = 0;
        }

        // Now make external calls after state is updated
        if (shouldRemove) {
            validators.removeValidator(val);
        } else if (shouldRemoveIncoming) {
            validators.removeValidatorIncoming(val);
        }

        emit LogPunishValidator(val, block.timestamp);
    }

    function decreaseMissedBlocksCounter(uint256 epoch)
        external
        onlyMiner
        onlyNotDecreased
        onlyInitialized
        onlyBlockEpoch(epoch)
    {
        decreased[block.number] = true;
        if (punishValidators.length == 0) {
            return;
        }

        // SECURITY FIX: Limit the number of validators processed per transaction
        uint256 processCount = punishValidators.length > MAX_VALIDATORS_PER_TX ? 
                              MAX_VALIDATORS_PER_TX : punishValidators.length;
        
        for (uint256 i = 0; i < processCount; i++) {
            if (
                punishRecords[punishValidators[i]].missedBlocksCounter >
                removeThreshold / decreaseRate
            ) {
                punishRecords[punishValidators[i]].missedBlocksCounter =
                    punishRecords[punishValidators[i]].missedBlocksCounter -
                    removeThreshold /
                    decreaseRate;
            } else {
                punishRecords[punishValidators[i]].missedBlocksCounter = 0;
            }
        }

        emit LogDecreaseMissedBlocksCounter();
    }

    // clean validator's punish record if one restake in
    function cleanPunishRecord(address val)
        public
        onlyInitialized
        onlyValidatorsContract
        returns (bool)
    {
        if (punishRecords[val].missedBlocksCounter != 0) {
            punishRecords[val].missedBlocksCounter = 0;
        }

        // remove it out of array if exist
        if (punishRecords[val].exist && punishValidators.length > 0) {
            if (punishRecords[val].index != punishValidators.length - 1) {
                address uval = punishValidators[punishValidators.length - 1];
                punishValidators[punishRecords[val].index] = uval;

                punishRecords[uval].index = punishRecords[val].index;
            }
            punishValidators.pop();
            punishRecords[val].index = 0;
            punishRecords[val].exist = false;
        }

        return true;
    }

    function getPunishValidatorsLen() public view returns (uint256) {
        return punishValidators.length;
    }

    function getPunishRecord(address val) public view returns (uint256) {
        return punishRecords[val].missedBlocksCounter;
    }
}
