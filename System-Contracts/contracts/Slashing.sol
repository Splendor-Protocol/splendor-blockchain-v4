// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Params.sol";
import "./Validators.sol";

contract Slashing is Params {
    
    struct DoubleSignEvidence {
        uint256 blockNumber;
        bytes32 blockHash1;
        bytes32 blockHash2;
        bytes signature1;
        bytes signature2;
        address validator;
        uint256 timestamp;
        bool processed;
    }
    
    struct SlashingRecord {
        uint256 totalSlashed;
        uint256 lastSlashTime;
        uint256 doubleSignCount;
        bool isSlashed;
    }
    
    Validators validators;
    
    // Slashing parameters - FIXED: Reasonable amounts based on validator tiers
    uint256 public doubleSignSlashAmount = 400 * 1e18; // 400 tokens (10% of Bronze minimum)
    uint256 public doubleSignJailTime = 86400; // 24 hours in blocks (1 block = 1 second)
    uint256 public evidenceValidityPeriod = 86400; // Evidence valid for 24 hours
    uint256 public maxSlashingPercentage = 20; // Max 20% of stake can be slashed (reduced from 50%)
    
    // Storage
    mapping(address => SlashingRecord) public slashingRecords;
    mapping(bytes32 => DoubleSignEvidence) public evidences;
    mapping(address => mapping(uint256 => bytes32)) public validatorBlockHashes; // validator => blockNumber => blockHash
    mapping(address => uint256) public jailedUntil;
    
    bytes32[] public evidenceList;
    address[] public slashedValidators;
    
    // Events
    event DoubleSignReported(address indexed validator, uint256 blockNumber, bytes32 evidence);
    event ValidatorSlashed(address indexed validator, uint256 amount, string reason);
    event ValidatorJailed(address indexed validator, uint256 jailedUntil);
    event EvidenceProcessed(bytes32 indexed evidenceHash, bool valid);
    
    modifier onlyNotSlashed(address validator) {
        require(!slashingRecords[validator].isSlashed, "Validator is slashed");
        _;
    }
    
    modifier onlyNotJailed(address validator) {
        require(block.number > jailedUntil[validator], "Validator is jailed");
        _;
    }
    
    function initialize() external onlyNotInitialized {
        validators = Validators(ValidatorContractAddr);
        initialized = true;
    }
    
    /**
     * @dev Report double signing evidence
     * @param blockNumber The block number where double signing occurred
     * @param blockHash1 First block hash signed by validator
     * @param blockHash2 Second block hash signed by validator (different from first)
     * @param signature1 Signature for first block
     * @param signature2 Signature for second block
     */
    function reportDoubleSign(
        uint256 blockNumber,
        bytes32 blockHash1,
        bytes32 blockHash2,
        bytes calldata signature1,
        bytes calldata signature2
    ) external onlyInitialized {
        require(blockHash1 != blockHash2, "Block hashes must be different");
        require(signature1.length == 65, "Invalid signature1 length");
        require(signature2.length == 65, "Invalid signature2 length");
        require(block.number <= blockNumber + evidenceValidityPeriod, "Evidence too old");
        
        // Recover validator addresses from signatures
        address validator1 = recoverSigner(blockHash1, signature1);
        address validator2 = recoverSigner(blockHash2, signature2);
        
        require(validator1 == validator2, "Signatures from different validators");
        require(validators.isActiveValidator(validator1), "Not an active validator");
        
        // Create evidence hash
        bytes32 evidenceHash = keccak256(abi.encodePacked(
            blockNumber, blockHash1, blockHash2, signature1, signature2, validator1
        ));
        
        require(!evidences[evidenceHash].processed, "Evidence already processed");
        
        // Store evidence
        evidences[evidenceHash] = DoubleSignEvidence({
            blockNumber: blockNumber,
            blockHash1: blockHash1,
            blockHash2: blockHash2,
            signature1: signature1,
            signature2: signature2,
            validator: validator1,
            timestamp: block.timestamp,
            processed: false
        });
        
        evidenceList.push(evidenceHash);
        
        emit DoubleSignReported(validator1, blockNumber, evidenceHash);
        
        // Process the evidence immediately
        _processDoubleSignEvidence(evidenceHash);
    }
    
    /**
     * @dev Process double signing evidence and apply slashing
     */
    function _processDoubleSignEvidence(bytes32 evidenceHash) internal {
        DoubleSignEvidence storage evidence = evidences[evidenceHash];
        require(!evidence.processed, "Evidence already processed");
        
        address validator = evidence.validator;
        
        // Verify the evidence is valid
        bool isValid = _verifyDoubleSignEvidence(evidence);
        
        // SECURITY FIX: Update state BEFORE external calls
        evidence.processed = true;
        
        if (isValid) {
            // Update slashing record before external calls
            slashingRecords[validator].doubleSignCount++;
            slashingRecords[validator].lastSlashTime = block.timestamp;
            
            // Apply slashing
            _slashValidator(validator, doubleSignSlashAmount, "Double signing");
            
            // Jail the validator
            _jailValidator(validator, doubleSignJailTime);
            
            // Remove from active validator set (external call)
            validators.removeValidator(validator);
        }
        
        emit EvidenceProcessed(evidenceHash, isValid);
    }
    
    /**
     * @dev Verify double signing evidence
     */
    function _verifyDoubleSignEvidence(DoubleSignEvidence memory evidence) internal pure returns (bool) {
        // Verify signatures are valid and from the same validator
        address signer1 = recoverSigner(evidence.blockHash1, evidence.signature1);
        address signer2 = recoverSigner(evidence.blockHash2, evidence.signature2);
        
        return (signer1 == evidence.validator && 
                signer2 == evidence.validator && 
                evidence.blockHash1 != evidence.blockHash2);
    }
    
    /**
     * @dev Slash a validator's stake
     */
    function _slashValidator(address validator, uint256 amount, string memory reason) internal {
        // Get validator's current stake
        uint256 currentStake = validators.getValidatorStake(validator);
        
        // Calculate maximum slashable amount (50% of stake)
        uint256 maxSlashable = (currentStake * maxSlashingPercentage) / 100;
        
        // Use minimum of requested amount and max slashable
        uint256 slashAmount = amount > maxSlashable ? maxSlashable : amount;
        
        if (slashAmount > 0) {
            // Update slashing record
            slashingRecords[validator].totalSlashed += slashAmount;
            slashingRecords[validator].isSlashed = true;
            
            // Add to slashed validators list if not already there
            if (slashingRecords[validator].totalSlashed == slashAmount) {
                slashedValidators.push(validator);
            }
            
            // Slash the stake (reduce validator's stake)
            validators.slashValidator(validator, slashAmount);
            
            emit ValidatorSlashed(validator, slashAmount, reason);
        }
    }
    
    /**
     * @dev Jail a validator for a specified period
     */
    function _jailValidator(address validator, uint256 jailPeriod) internal {
        jailedUntil[validator] = block.number + jailPeriod;
        emit ValidatorJailed(validator, jailedUntil[validator]);
    }
    
    /**
     * @dev Recover signer address from message hash and signature
     */
    function recoverSigner(bytes32 messageHash, bytes memory signature) internal pure returns (address) {
        require(signature.length == 65, "Invalid signature length");
        
        bytes32 r;
        bytes32 s;
        uint8 v;
        
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        
        if (v < 27) {
            v += 27;
        }
        
        require(v == 27 || v == 28, "Invalid signature v value");
        
        return ecrecover(messageHash, v, r, s);
    }
    
    /**
     * @dev Check if validator is currently jailed
     */
    function isJailed(address validator) external view returns (bool) {
        return block.number <= jailedUntil[validator];
    }
    
    /**
     * @dev Get slashing record for a validator
     */
    function getSlashingRecord(address validator) external view returns (
        uint256 totalSlashed,
        uint256 lastSlashTime,
        uint256 doubleSignCount,
        bool isSlashed
    ) {
        SlashingRecord memory record = slashingRecords[validator];
        return (record.totalSlashed, record.lastSlashTime, record.doubleSignCount, record.isSlashed);
    }
    
    /**
     * @dev Get evidence details
     */
    function getEvidence(bytes32 evidenceHash) external view returns (
        uint256 blockNumber,
        bytes32 blockHash1,
        bytes32 blockHash2,
        address validator,
        uint256 timestamp,
        bool processed
    ) {
        DoubleSignEvidence memory evidence = evidences[evidenceHash];
        return (
            evidence.blockNumber,
            evidence.blockHash1,
            evidence.blockHash2,
            evidence.validator,
            evidence.timestamp,
            evidence.processed
        );
    }
    
    /**
     * @dev Get total number of evidences
     */
    function getEvidenceCount() external view returns (uint256) {
        return evidenceList.length;
    }
    
    /**
     * @dev Get evidence hash by index
     */
    function getEvidenceByIndex(uint256 index) external view returns (bytes32) {
        require(index < evidenceList.length, "Index out of bounds");
        return evidenceList[index];
    }
    
    /**
     * @dev Get total number of slashed validators
     */
    function getSlashedValidatorsCount() external view returns (uint256) {
        return slashedValidators.length;
    }
    
    /**
     * @dev Get slashed validator by index
     */
    function getSlashedValidatorByIndex(uint256 index) external view returns (address) {
        require(index < slashedValidators.length, "Index out of bounds");
        return slashedValidators[index];
    }
    
    /**
     * @dev Admin function to update slashing parameters
     */
    function updateSlashingParams(
        uint256 _doubleSignSlashAmount,
        uint256 _doubleSignJailTime,
        uint256 _evidenceValidityPeriod,
        uint256 _maxSlashingPercentage
    ) external onlyValidatorsContract {
        require(_maxSlashingPercentage <= 100, "Max slashing percentage cannot exceed 100%");
        
        doubleSignSlashAmount = _doubleSignSlashAmount;
        doubleSignJailTime = _doubleSignJailTime;
        evidenceValidityPeriod = _evidenceValidityPeriod;
        maxSlashingPercentage = _maxSlashingPercentage;
    }
    
    /**
     * @dev Unjail a validator - can only be called by Proposal contract after validator voting
     */
    function unjailValidator(address validator) external onlyProposalContract {
        require(jailedUntil[validator] > 0, "Validator is not jailed");
        jailedUntil[validator] = 0;
        
        // Clear slashing status to allow validator to participate again
        slashingRecords[validator].isSlashed = false;
        
        emit ValidatorJailed(validator, 0); // Emit with 0 to indicate unjailed
    }
    
    /**
     * @dev Emergency function to clear slashing record (validators contract only) - for extreme cases
     */
    function emergencyClearSlashing(address validator) external onlyValidatorsContract {
        slashingRecords[validator] = SlashingRecord(0, 0, 0, false);
        jailedUntil[validator] = 0;
    }
}
