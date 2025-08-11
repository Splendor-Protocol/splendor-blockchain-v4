// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Params {
    bool public initialized;

    // System contracts
    address payable
        public constant ValidatorContractAddr = payable(0x000000000000000000000000000000000000f000);
    address
        public constant PunishContractAddr = 0x000000000000000000000000000000000000F001;
    address
        public constant ProposalAddr = 0x000000000000000000000000000000000000F002;
    address
        public constant SlashingContractAddr = 0x000000000000000000000000000000000000f007;

    // System params
    uint16 public constant MaxValidators = 10000;
    // Validator have to wait StakingLockPeriod blocks to withdraw staking
    uint64 public constant StakingLockPeriod = 86400;
    uint256 public constant MinimalStakingCoin = 32 ether;
    
    // Tiered validator system
    uint256 public constant BronzeValidatorStaking = 3947 ether;    // ~$1,500
    uint256 public constant SilverValidatorStaking = 39474 ether;   // ~$15,000  
    uint256 public constant GoldValidatorStaking = 394737 ether;    // ~$150,000
    
    // minimum initial staking to become a validator (Bronze tier)
    uint256 public constant minimumValidatorStaking = BronzeValidatorStaking;


    // percent distribution of Gas Fee earned by validator 100000 = 100%
    uint public constant stakerPartPercent = 30000;          //30% - Stakers (passive participation)
    uint public constant validatorPartPercent = 60000;       //60% - Validators (they invest and run infrastructure)
    uint public constant creatorPartPercent = 10000;         //10% - Creator (protocol development)
    uint256 public constant extraRewardsPerBlock = 1 ether;  //  extra rewards will be added for distrubution
    uint256 public rewardFund ;
    uint256 public totalRewards;



    modifier onlyMiner() {
        require(msg.sender == block.coinbase, "Miner only");
        _;
    }

    modifier onlyNotInitialized() {
        require(!initialized, "Already initialized");
        _;
    }

    modifier onlyInitialized() {
        require(initialized, "Not init yet");
        _;
    }

    modifier onlyPunishContract() {
        require(msg.sender == PunishContractAddr, "Punish contract only");
        _;
    }

    modifier onlyBlockEpoch(uint256 epoch) {
        require(block.number % epoch == 0, "Block epoch only");
        _;
    }

    modifier onlyValidatorsContract() {
        require(
            msg.sender == ValidatorContractAddr,
            "Validators contract only"
        );
        _;
    }

    modifier onlyProposalContract() {
        require(msg.sender == ProposalAddr, "Proposal contract only");
        _;
    }

    modifier onlySlashingContract() {
        require(msg.sender == 0x000000000000000000000000000000000000F003, "Slashing contract only");
        _;
    }
}
