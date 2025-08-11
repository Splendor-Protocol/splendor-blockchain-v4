// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;



interface InterfaceValidator {
    enum Status {
        // validator not exist, default status
        NotExist,
        // validator created
        Created,
        // anyone has staked for the validator
        Staked,
        // validator's staked coins < MinimalStakingCoin
        Unstaked,
        // validator is jailed by system(validator have to repropose)
        Jailed
    }
    struct Description {
        string moniker;
    }
    function getTopValidators() external view returns(address[] memory);
    function getValidatorInfo(address val)external view returns(address payable, Status, uint256, uint256, uint256, address[] memory);
    function getValidatorDescription(address val) external view returns (string memory);
    function totalStake() external view returns(uint256);
    function getStakingInfo(address staker, address validator) external view returns(uint256, uint256, uint256);
    function viewStakeReward(address _staker, address _validator) external view returns(uint256);
    function MinimalStakingCoin() external view returns(uint256);
    function isTopValidator(address who) external view returns (bool);
    function StakingLockPeriod() external view returns(uint64);
    function UnstakeLockPeriod() external view returns(uint64);
    function WithdrawProfitPeriod() external view returns(uint64);


    //write functions
    function createOrEditValidator(
        address payable feeAddr,
        string calldata moniker
    ) external payable  returns (bool);

    function unstake(address validator)
        external
        returns (bool);

    function withdrawProfits(address validator) external returns (bool);
}


/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
 
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
 
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;
 
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
 
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }
 
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }
 
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }
 
    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }
 
    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
 
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }
 
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
 
contract ValidatorController is Ownable {

    InterfaceValidator public valContract = InterfaceValidator(0x000000000000000000000000000000000000f000);
    uint256 public minimumValidatorStaking = 3947 * 1e18; // Bronze tier minimum
    uint256 public lastRewardedBlock;
    uint256 public extraRewardsPerBlock = 1 * 1e18;
    uint256 public rewardFund;    
    mapping(address=>uint256) public rewardBalance;
    mapping(address=>uint256) public totalProfitWithdrawn;
    
    // Per-validator block tracking for fair rewards
    mapping(address => uint256) public lastClaimBlock;
    
    // Selective reward system - only approved validators get annual staking rewards
    mapping(address => bool) public approvedForRewards;
    address[] public approvedValidators;
    
    // Track when validators were approved for calculating annual rewards
    mapping(address => uint256) public approvalTimestamp;
    mapping(address => uint256) public lastAnnualRewardClaim;
    
    // Multi-admin system
    mapping(address => bool) public admins;
    address[] public adminList;
    
    // Pause functionality
    bool public paused = false;
    
    // Annual reward rate (100% = 10000, so 100% annual return)
    uint256 public annualRewardRate = 10000; // 100% annual return
    uint256 public constant RATE_PRECISION = 10000;
    uint256 public constant SECONDS_PER_YEAR = 365 days;
    
    // Price oracle system for dollar-based rewards
    uint256 public splendorPriceUSD = 38; // Price in cents (0.38 USD = 38 cents)
    uint256 public constant PRICE_PRECISION = 100; // For cents precision
    uint256 public lastPriceUpdate;
    address public priceOracle; // Address authorized to update price
    uint256 public constant PRICE_UPDATE_COOLDOWN = 24 hours; // 24 hour cooldown between price updates
    
    // Tier-based reward system
    bool public useTierBasedRewards = true; // Use tier-based rewards by default
    
    // Validator tiers and their annual USD rewards (in cents)
    struct ValidatorTier {
        uint256 minStakingAmount;    // Minimum staking amount in SPLD (18 decimals)
        uint256 annualRewardCents;   // Annual reward in cents
        string tierName;             // Tier name for display
    }
    
    ValidatorTier[3] public validatorTiers;
    
    //events
    event Stake(address validator, uint256 amount, uint256 timestamp);
    event Unstake(address validator, uint256 timestamp);
    event WithdrawProfit(address validator, uint256 amount, uint256 timestamp);
    event ValidatorApprovedForRewards(address validator, bool approved);
    event RewardsDistributed(address[] validators, uint256 totalAmount);
    event AdminAdded(address admin);
    event AdminRemoved(address admin);
    event FundsTransferred(address to, uint256 amount);
    event PriceUpdated(uint256 newPriceInCents, uint256 timestamp);
    event RewardSystemToggled(bool useDollarBased);
    event AnnualDollarRewardUpdated(uint256 dollarAmountInCents);
    event ContractPaused(address by, uint256 timestamp);
    event ContractUnpaused(address by, uint256 timestamp);
    
    // Modifier for admin-only functions
    modifier onlyAdmin() {
        require(admins[msg.sender] || msg.sender == owner(), "Not authorized: must be admin or owner");
        _;
    }
    
    // Modifier for pause functionality
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }
    
    constructor() {
        // Owner is automatically an admin
        admins[msg.sender] = true;
        adminList.push(msg.sender);
        
        // Initialize validator tiers based on $0.38 SPLD price
        // Tier 1: $1,500 ÷ $0.38 = 3,947 SPLD → earns $1,500/year
        validatorTiers[0] = ValidatorTier({
            minStakingAmount: 3947 * 1e18,  // 3,947 SPLD
            annualRewardCents: 150000,      // $1,500 in cents
            tierName: "Tier 1"
        });
        
        // Tier 2: $15,000 ÷ $0.38 = 39,474 SPLD → earns $15,000/year  
        validatorTiers[1] = ValidatorTier({
            minStakingAmount: 39474 * 1e18, // 39,474 SPLD
            annualRewardCents: 1500000,     // $15,000 in cents
            tierName: "Tier 2"
        });
        
        // Tier 3: $150,000 ÷ $0.38 = 394,737 SPLD → earns $150,000/year
        validatorTiers[2] = ValidatorTier({
            minStakingAmount: 394737 * 1e18, // 394,737 SPLD
            annualRewardCents: 15000000,     // $150,000 in cents
            tierName: "Tier 3"
        });
    }

    receive() external payable {
        rewardFund += msg.value;
    }


    function createOrEditValidator(
        address payable feeAddr,
        string calldata moniker
    ) external payable  returns (bool) {

        require(msg.value >= minimumValidatorStaking, "Please stake minimum validator staking" );

        valContract.createOrEditValidator{value: msg.value}(feeAddr, moniker);

        emit Stake(msg.sender, msg.value, block.timestamp);

        return true;
    }


    function unstake(address validator)
        external
        returns (bool)
    {
        valContract.unstake(validator);

        emit Unstake(msg.sender, block.timestamp);
        return true;
    }

    // Tier-based reward function: Claims annual rewards based on validator's tier
    function withdrawStakingReward(address validator) external whenNotPaused {
        require(validator == tx.origin, "caller should be real validator");
        require(approvedForRewards[validator], "Validator not approved for rewards");
        
        // Only annual tier-based rewards (block rewards disabled)
        uint256 annualRewards = viewAnnualStakingReward(validator);
        
        require(annualRewards > 0, "No annual rewards available");
        require(address(this).balance >= annualRewards, "Insufficient contract balance");
        
        valContract.withdrawProfits(validator);
        
        // Update annual reward tracking
        lastAnnualRewardClaim[validator] = block.timestamp;
        
        // Update reward fund
        if (annualRewards <= rewardFund) {
            rewardFund -= annualRewards;
        } else {
            rewardFund = 0;
        }
        
        totalProfitWithdrawn[validator] += annualRewards;
        
        payable(validator).transfer(annualRewards);
        
        emit WithdrawProfit(validator, annualRewards, block.timestamp);
    }

    // NEW: Withdraw annual staking rewards (100% of staked amount per year)
    function withdrawAnnualStakingReward(address validator) external whenNotPaused {
        require(validator == tx.origin, "caller should be real validator");
        require(approvedForRewards[validator], "Validator not approved for annual rewards");
        
        uint256 annualReward = viewAnnualStakingReward(validator);
        require(annualReward > 0, "No annual rewards available");
        require(address(this).balance >= annualReward, "Insufficient contract balance");
        
        // Update last claim timestamp
        lastAnnualRewardClaim[validator] = block.timestamp;
        
        // Update reward fund
        if (annualReward <= rewardFund) {
            rewardFund -= annualReward;
        } else {
            rewardFund = 0;
        }
        
        totalProfitWithdrawn[validator] += annualReward;
        
        payable(validator).transfer(annualReward);
        
        emit WithdrawProfit(validator, annualReward, block.timestamp);
    }

    // NEW: View annual staking reward available for withdrawal
    function viewAnnualStakingReward(address validator) public view returns(uint256) {
        if (!approvedForRewards[validator]) {
            return 0;
        }
        
        if (approvalTimestamp[validator] == 0) {
            return 0;
        }
        
        // Get validator's staked amount
        (uint256 stakedAmount, , ) = valContract.getStakingInfo(validator, validator);
        if (stakedAmount == 0) {
            return 0;
        }
        
        // Calculate time since last claim
        uint256 timeSinceLastClaim = block.timestamp - lastAnnualRewardClaim[validator];
        
        uint256 annualReward;
        
        if (useTierBasedRewards) {
            // Tier-based rewards: Fixed dollar amount based on validator tier
            uint256 tierRewardCents = getValidatorTierReward(stakedAmount);
            if (tierRewardCents == 0) {
                return 0; // Validator doesn't meet minimum tier requirements
            }
            
            // Convert tier reward from cents to SPLD tokens based on current price
            // tierRewardCents / splendorPriceUSD = annual reward in SPLD
            // Then calculate pro-rated amount based on time since last claim
            annualReward = (tierRewardCents * 1e18 * timeSinceLastClaim) / (splendorPriceUSD * SECONDS_PER_YEAR);
        } else {
            // Percentage-based rewards: 100% of staked amount per year
            annualReward = (stakedAmount * annualRewardRate * timeSinceLastClaim) / (RATE_PRECISION * SECONDS_PER_YEAR);
        }
        
        return annualReward;
    }

    // NEW: Get validator tier reward based on staked amount
    function getValidatorTierReward(uint256 stakedAmount) public view returns(uint256 tierRewardCents) {
        // Check tiers from highest to lowest
        for (int256 i = 2; i >= 0; i--) {
            if (stakedAmount >= validatorTiers[uint256(i)].minStakingAmount) {
                return validatorTiers[uint256(i)].annualRewardCents;
            }
        }
        return 0; // Doesn't meet minimum tier requirements
    }

    // NEW: Get validator tier info
    function getValidatorTierInfo(address validator) external view returns (
        uint256 currentTier,
        string memory tierName,
        uint256 minStakingRequired,
        uint256 annualRewardCents,
        uint256 stakedAmount,
        bool meetsRequirement
    ) {
        (stakedAmount, , ) = valContract.getStakingInfo(validator, validator);
        
        // Find the validator's current tier
        for (uint256 i = 2; i >= 0; i--) {
            if (stakedAmount >= validatorTiers[i].minStakingAmount) {
                return (
                    i + 1, // Tier number (1-based)
                    validatorTiers[i].tierName,
                    validatorTiers[i].minStakingAmount,
                    validatorTiers[i].annualRewardCents,
                    stakedAmount,
                    true
                );
            }
        }
        
        // Doesn't meet minimum tier requirements
        return (0, "No Tier", validatorTiers[0].minStakingAmount, 0, stakedAmount, false);
    }

    function viewValidatorRewards(address validator) public view returns(uint256 rewardAmount){
        // Block rewards disabled - only tier-based annual rewards
        return rewardBalance[validator];        
    }

    // Internal function to approve/disapprove validators for annual staking rewards
    function _setValidatorRewardApproval(address validator, bool approved) internal {
        require(validator != address(0), "Invalid validator address");
        
        bool wasApproved = approvedForRewards[validator];
        approvedForRewards[validator] = approved;
        
        if (approved && !wasApproved) {
            // Add to approved list and set approval timestamp
            approvedValidators.push(validator);
            approvalTimestamp[validator] = block.timestamp;
            lastAnnualRewardClaim[validator] = block.timestamp;
        } else if (!approved && wasApproved) {
            // Remove from approved list and reset timestamps
            for (uint256 i = 0; i < approvedValidators.length; i++) {
                if (approvedValidators[i] == validator) {
                    approvedValidators[i] = approvedValidators[approvedValidators.length - 1];
                    approvedValidators.pop();
                    break;
                }
            }
            approvalTimestamp[validator] = 0;
            lastAnnualRewardClaim[validator] = 0;
        }
        
        emit ValidatorApprovedForRewards(validator, approved);
    }

    // Admin function to approve/disapprove validators for annual staking rewards
    function setValidatorRewardApproval(address validator, bool approved) external onlyAdmin {
        _setValidatorRewardApproval(validator, approved);
    }

    // NEW: Admin function to approve multiple validators at once
    function setMultipleValidatorRewardApproval(address[] calldata validators, bool approved) external onlyAdmin {
        for (uint256 i = 0; i < validators.length; i++) {
            _setValidatorRewardApproval(validators[i], approved);
        }
    }

    // Fair distribution function (from test contract)
    function _distributeRewards() internal {
        address[] memory highestValidatorsSet = valContract.getTopValidators();
        uint256 totalValidators = highestValidatorsSet.length;

        for(uint8 i=0; i < totalValidators; i++){
            rewardBalance[highestValidatorsSet[i]] = viewValidatorRewards(highestValidatorsSet[i]);
        }
        lastRewardedBlock = block.number;        
    }

    // NEW: Admin function to manually distribute rewards to approved validators
    function distributeRewardsToApproved() external onlyAdmin {
        require(approvedValidators.length > 0, "No approved validators");
        
        uint256 totalRewardAmount = 0;
        
        for (uint256 i = 0; i < approvedValidators.length; i++) {
            address validator = approvedValidators[i];
            uint256 reward = viewValidatorRewards(validator);
            if (reward > 0) {
                rewardBalance[validator] = reward;
                totalRewardAmount += reward;
            }
        }
        
        lastRewardedBlock = block.number;
        
        emit RewardsDistributed(approvedValidators, totalRewardAmount);
    }

    // NEW: View function to get all approved validators
    function getApprovedValidators() external view returns (address[] memory) {
        return approvedValidators;
    }

    // NEW: View function to check if validator is approved for rewards
    function isValidatorApprovedForRewards(address validator) external view returns (bool) {
        return approvedForRewards[validator];
    }

    // NEW: View function to get approved validators count
    function getApprovedValidatorsCount() external view returns (uint256) {
        return approvedValidators.length;
    }

    // NEW: Admin management functions
    function addAdmin(address newAdmin) external onlyOwner {
        require(newAdmin != address(0), "Invalid admin address");
        require(!admins[newAdmin], "Already an admin");
        
        admins[newAdmin] = true;
        adminList.push(newAdmin);
        
        emit AdminAdded(newAdmin);
    }

    function removeAdmin(address admin) external onlyOwner {
        require(admin != address(0), "Invalid admin address");
        require(admins[admin], "Not an admin");
        require(admin != owner(), "Cannot remove owner as admin");
        
        admins[admin] = false;
        
        // Remove from admin list
        for (uint256 i = 0; i < adminList.length; i++) {
            if (adminList[i] == admin) {
                adminList[i] = adminList[adminList.length - 1];
                adminList.pop();
                break;
            }
        }
        
        emit AdminRemoved(admin);
    }

    function isAdmin(address account) external view returns (bool) {
        return admins[account] || account == owner();
    }

    function getAdminList() external view returns (address[] memory) {
        return adminList;
    }

    function getAdminCount() external view returns (uint256) {
        return adminList.length;
    }

    // NEW: Transfer function for moving funds
    function transferFunds(address payable to, uint256 amount) external onlyAdmin {
        require(to != address(0), "Invalid recipient address");
        require(amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= amount, "Insufficient contract balance");
        
        // Update reward fund if transferring from it
        if (amount <= rewardFund) {
            rewardFund -= amount;
        } else {
            rewardFund = 0;
        }
        
        to.transfer(amount);
        
        emit FundsTransferred(to, amount);
    }

    // NEW: Emergency transfer function (owner only)
    function emergencyTransfer(address payable to, uint256 amount) external onlyOwner {
        require(to != address(0), "Invalid recipient address");
        require(amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= amount, "Insufficient contract balance");
        
        to.transfer(amount);
        
        emit FundsTransferred(to, amount);
    }

    /**
        admin functions
    */
    function rescueCoins() external onlyOwner{
        rewardFund -= address(this).balance;
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function changeMinimumValidatorStaking(uint256 amount) external onlyOwner{
        minimumValidatorStaking = amount;
    }

    function changeExtraRewardsPerBlock(uint256 amount) external onlyOwner{
        extraRewardsPerBlock = amount;
    }

    // NEW: Disable block rewards completely (recommended fix)
    function disableBlockRewards() external onlyOwner {
        extraRewardsPerBlock = 0;
    }

    // NEW: Admin function to reset lastRewardedBlock (fixes the massive reward bug)
    function resetLastRewardedBlock() external onlyAdmin {
        lastRewardedBlock = block.number;
    }

    // NEW: Admin function to set lastRewardedBlock to a specific block (for precise control)
    function setLastRewardedBlock(uint256 blockNumber) external onlyOwner {
        require(blockNumber <= block.number, "Cannot set future block");
        lastRewardedBlock = blockNumber;
    }

    // NEW: Change annual reward rate (owner only)
    function changeAnnualRewardRate(uint256 newRate) external onlyOwner {
        require(newRate <= 50000, "Annual reward rate cannot exceed 500%"); // Max 500% annual return
        annualRewardRate = newRate;
    }

    // NEW: Price oracle management functions
    function setPriceOracle(address newOracle) external onlyOwner {
        require(newOracle != address(0), "Invalid oracle address");
        priceOracle = newOracle;
    }

    function updateSplendorPrice(uint256 newPriceInCents) external {
        require(msg.sender == priceOracle || msg.sender == owner(), "Not authorized to update price");
        require(newPriceInCents > 0, "Price must be greater than 0");
        require(newPriceInCents <= 100000, "Price too high (max $1000)"); // Max $1000 per token
        require(block.timestamp >= lastPriceUpdate + PRICE_UPDATE_COOLDOWN, "Price can only be updated once every 24 hours");
        
        splendorPriceUSD = newPriceInCents;
        lastPriceUpdate = block.timestamp;
        
        emit PriceUpdated(newPriceInCents, block.timestamp);
    }

    function toggleRewardSystem(bool useTierBased) external onlyOwner {
        useTierBasedRewards = useTierBased;
        emit RewardSystemToggled(useTierBased);
    }

    // NEW: Update validator tier (owner only)
    function updateValidatorTier(uint256 tierIndex, uint256 minStakingAmount, uint256 annualRewardCents, string calldata tierName) external onlyOwner {
        require(tierIndex < 3, "Invalid tier index");
        require(minStakingAmount > 0, "Staking amount must be greater than 0");
        require(annualRewardCents > 0, "Reward amount must be greater than 0");
        
        validatorTiers[tierIndex] = ValidatorTier({
            minStakingAmount: minStakingAmount,
            annualRewardCents: annualRewardCents,
            tierName: tierName
        });
    }

    // NEW: View functions for price and reward system
    function getPriceInfo() external view returns (
        uint256 currentPriceInCents,
        uint256 lastUpdate,
        address oracle,
        bool isTierBasedRewards
    ) {
        return (
            splendorPriceUSD,
            lastPriceUpdate,
            priceOracle,
            useTierBasedRewards
        );
    }

    function calculateDollarValueOfReward(address validator) external view returns (uint256 dollarValueInCents) {
        uint256 tokenReward = viewAnnualStakingReward(validator);
        if (tokenReward == 0) {
            return 0;
        }
        
        // Convert token reward to dollar value
        dollarValueInCents = (tokenReward * splendorPriceUSD) / 1e18;
        return dollarValueInCents;
    }

    // NEW: Get validator approval info
    function getValidatorApprovalInfo(address validator) external view returns (
        bool isApproved,
        uint256 approvedTimestamp,
        uint256 lastClaimTimestamp,
        uint256 availableAnnualReward
    ) {
        return (
            approvedForRewards[validator],
            approvalTimestamp[validator],
            lastAnnualRewardClaim[validator],
            viewAnnualStakingReward(validator)
        );
    }

    // NEW: Get total rewards available for a validator (both types)
    function getTotalAvailableRewards(address validator) external view returns (
        uint256 blockRewards,
        uint256 annualRewards,
        uint256 totalRewards
    ) {
        blockRewards = viewValidatorRewards(validator);
        annualRewards = viewAnnualStakingReward(validator);
        totalRewards = blockRewards + annualRewards;
        
        return (blockRewards, annualRewards, totalRewards);
    }

    /**
        View functions
    */

    function getAllValidatorInfo() external view returns (uint256 totalValidatorCount,uint256 totalStakedCoins,address[] memory,InterfaceValidator.Status[] memory,uint256[] memory,string[] memory,string[] memory)
    {
        address[] memory highestValidatorsSet = valContract.getTopValidators();
       
        uint256 totalValidators = highestValidatorsSet.length;
	    uint256 totalunstaked ;
        InterfaceValidator.Status[] memory statusArray = new InterfaceValidator.Status[](totalValidators);
        uint256[] memory coinsArray = new uint256[](totalValidators);
        string[] memory identityArray = new string[](totalValidators);
        string[] memory websiteArray = new string[](totalValidators);
        
        for(uint8 i=0; i < totalValidators; i++){
            (, InterfaceValidator.Status status, uint256 coins, , , ) = valContract.getValidatorInfo(highestValidatorsSet[i]);
	        if(coins>0 ){
                string memory moniker = valContract.getValidatorDescription(highestValidatorsSet[i]);
                
                statusArray[i] = status;
                coinsArray[i] = coins;
                identityArray[i] = moniker;
                websiteArray[i] = ""; // No website field anymore
 	        }
            else
            {
                totalunstaked += 1;
	        }
        }
        return(totalValidators - totalunstaked , valContract.totalStake(), highestValidatorsSet, statusArray, coinsArray, identityArray, websiteArray);
    }


    function validatorSpecificInfo1(address validatorAddress, address /* user */) external view returns(string memory identityName, string memory website, string memory otherDetails, uint256 withdrawableRewards, uint256 stakedCoins, uint256 waitingBlocksForUnstake ){
        
        string memory moniker = valContract.getValidatorDescription(validatorAddress);
        
        uint256 unstakeBlock;

        (stakedCoins, unstakeBlock, ) = valContract.getStakingInfo(validatorAddress,validatorAddress);

        if(unstakeBlock!=0){
            waitingBlocksForUnstake = stakedCoins;
            stakedCoins = 0;
        }        

        return(moniker, "", "", viewValidatorRewards(validatorAddress), stakedCoins, waitingBlocksForUnstake) ;
    }


    function validatorSpecificInfo2(address validatorAddress, address user) external view returns(uint256 totalStakedCoins, InterfaceValidator.Status status, uint256 selfStakedCoins, uint256 masterVoters, uint256 stakers, address){
        address[] memory stakersArray;
        (, status, totalStakedCoins, , , stakersArray)  = valContract.getValidatorInfo(validatorAddress);

        (selfStakedCoins, , ) = valContract.getStakingInfo(validatorAddress,validatorAddress);

        return (totalStakedCoins, status, selfStakedCoins, 0, stakersArray.length, user);
    }

 
    function totalProfitEarned(address validator) public view returns(uint256){
        return totalProfitWithdrawn[validator] + viewValidatorRewards(validator);
    }
    
    function waitingWithdrawProfit(address /* user */, address /* validatorAddress */) external pure returns(uint256){
        // no waiting to withdraw profit.
        // this is kept for backward UI compatibility
        
       return 0;
    }

    function waitingUnstaking(address /* user */, address /* validator */) external pure returns(uint256){
        
        //this function is kept as it is for the UI compatibility
        //no waiting for unstaking
        return 0;
    }

    function waitingWithdrawStaking(address user, address validatorAddress) public view returns(uint256){
        
        //validator and delegators will have waiting 
   
        (, uint256 unstakeBlock, ) = valContract.getStakingInfo(user,validatorAddress);

        if(unstakeBlock==0){
            return 0;
        }
        
        if(unstakeBlock + valContract.StakingLockPeriod() > block.number){
            return 2 * ((unstakeBlock + valContract.StakingLockPeriod()) - block.number);
        }
        
       return 0;
                
    }

    function minimumStakingAmount() external view returns(uint256){
        return valContract.MinimalStakingCoin();
    }

    function stakingValidations(address user, address validatorAddress) external view returns(uint256 minimumStakingAmt, uint256 stakingWaiting){
        return (valContract.MinimalStakingCoin(), waitingWithdrawStaking(user, validatorAddress));
    }
    
    function checkValidator(address /* user */) external pure returns(bool){
        //this function is for UI compatibility
        return true;
    }

    // NEW: Pause functionality
    function pause() external onlyOwner {
        require(!paused, "Contract is already paused");
        paused = true;
        emit ContractPaused(msg.sender, block.timestamp);
    }

    function unpause() external onlyOwner {
        require(paused, "Contract is not paused");
        paused = false;
        emit ContractUnpaused(msg.sender, block.timestamp);
    }

    function isPaused() external view returns (bool) {
        return paused;
    }
}
