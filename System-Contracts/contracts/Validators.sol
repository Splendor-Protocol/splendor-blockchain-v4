// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Params.sol";
import "./Punish.sol";

contract Validators is Params {

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

    enum ValidatorTier {
        Bronze,  // 3,947 SPLD minimum
        Silver,  // 39,474 SPLD minimum  
        Gold     // 394,737 SPLD minimum
    }

    struct Description {
        string moniker;
    }

    struct Validator {
        address payable feeAddr;
        Status status;
        ValidatorTier tier;
        uint256 coins;
        Description description;
        uint256 hbIncoming;
        uint256 totalJailedHB;
        //uint256 lastWithdrawProfitsBlock;
        // Address list of user who has staked for this validator
        address[] stakers;
    }

    struct StakingInfo {
        uint256 coins;
        // unstakeBlock != 0 means that you are unstaking your stake, so you can't
        // stake or unstake
        uint256 unstakeBlock;
        // index of the staker list in validator
        uint256 index;
    }

    mapping(address => Validator) validatorInfo;
    // staker => validator => info
    mapping(address => mapping(address => StakingInfo)) staked;
    // current validator set used by chain
    // only changed at block epoch
    address[] public currentValidatorSet;
    // highest validator set(dynamic changed)
    address[] public highestValidatorsSet;
    // total stake of all validators
    uint256 public totalStake;
    // total jailed hb
    uint256 public totalJailedHB;



    mapping(address => address) public contractCreator;

    // staker => validator => lastRewardTime
    mapping(address => mapping(address => uint)) public stakeTime;
    //validator => LastRewardtime
    mapping( address => uint) public lastRewardTime;
    //validator => lastRewardTime => reflectionPerent
    mapping(address => mapping( uint => uint )) public reflectionPercentSum;


    // System contracts
    Punish punish;

    enum Operations {Distribute, UpdateValidators}
    // Record the operations is done or not.
    mapping(uint256 => mapping(uint8 => bool)) operationsDone;

    event LogCreateValidator(
        address indexed val,
        address indexed fee,
        uint256 time
    );
    event LogEditValidator(
        address indexed val,
        address indexed fee,
        uint256 time
    );
    event LogReactive(address indexed val, uint256 time);
    event LogAddToTopValidators(address indexed val, uint256 time);
    event LogRemoveFromTopValidators(address indexed val, uint256 time);
    event LogUnstake(
        address indexed staker,
        address indexed val,
        uint256 amount,
        uint256 time
    );
    event LogWithdrawStaking(
        address indexed staker,
        address indexed val,
        uint256 amount,
        uint256 time
    );
    event LogWithdrawProfits(
        address indexed val,
        address indexed fee,
        uint256 hb,
        uint256 time
    );
    event LogRemoveValidator(address indexed val, uint256 hb, uint256 time);
    event LogRemoveValidatorIncoming(
        address indexed val,
        uint256 hb,
        uint256 time
    );
    event LogDistributeBlockReward(
        address indexed coinbase,
        uint256 blockReward,
        uint256 time,
        address[] To,
        uint64[] Gass
    );
    event LogUpdateValidator(address[] newSet);
    event LogStake(
        address indexed staker,
        address indexed val,
        uint256 staking,
        uint256 time
    );

    event withdrawStakingRewardEv(address user,address validator,uint reward,uint timeStamp);

    modifier onlyNotRewarded() {
        require(
            operationsDone[block.number][uint8(Operations.Distribute)] == false,
            "Block is already rewarded"
        );
        _;
    }

    modifier onlyNotUpdated() {
        require(
            operationsDone[block.number][uint8(Operations.UpdateValidators)] ==
                false,
            "Validators already updated"
        );
        _;
    }

    receive() external payable {
      rewardFund += msg.value;
    }
    // This contract share of validator gain to creator of contract
    // It is advised to call this function your contract constructor to avoid intruders
    function setContractCreator(address _contract ) public returns(bool)
    {
        require(contractCreator[_contract] == address(0), "invalid call");
        contractCreator[_contract] = tx.origin;
        return true;
    }

    function initialize(address[] calldata vals) external onlyNotInitialized {
        punish = Punish(PunishContractAddr);

        for (uint256 i = 0; i < vals.length; i++) {
            require(vals[i] != address(0), "Invalid validator address");
            lastRewardTime[vals[i]] = block.timestamp;

            if (!isActiveValidator(vals[i])) {
                currentValidatorSet.push(vals[i]);
            }
            if (!isTopValidator(vals[i])) {
                highestValidatorsSet.push(vals[i]);
            }
            if (validatorInfo[vals[i]].feeAddr == address(0)) {
                validatorInfo[vals[i]].feeAddr = payable(vals[i]);
            }
            // Important: NotExist validator can't get profits
            if (validatorInfo[vals[i]].status == Status.NotExist) {
                validatorInfo[vals[i]].status = Status.Staked;
            }
        }

        initialized = true;
    }

    // stake for the validator
    function stake(address validator)
        public
        payable
        onlyInitialized
        returns (bool)
    {
        address payable staker = payable(tx.origin);
        uint256 staking = msg.value;

        require(
            validatorInfo[validator].status == Status.Created ||
                validatorInfo[validator].status == Status.Staked,
            "Can't stake to a validator in abnormal status"
        );

        require(
            staked[staker][validator].unstakeBlock == 0,
            "Can't stake when you are unstaking"
        );

        Validator storage valInfo = validatorInfo[validator];
        // The staked coins of validator must >= MinimalStakingCoin
        require(
            valInfo.coins + (staking) >= MinimalStakingCoin,
            "Staking coins not enough"
        );

        // stake at first time to this valiadtor
        if (staked[staker][validator].coins == 0) {
            if(staked[staker][validator].index == 0){
            // add staker to validator's record list
            staked[staker][validator].index = valInfo.stakers.length;
            valInfo.stakers.push(staker);
            if(lastRewardTime[validator] == 0)
            {
                lastRewardTime[validator] = block.timestamp;
            }
            stakeTime[staker][validator] = lastRewardTime[validator];
            }
        }
        else
        {
            withdrawStakingReward(validator);
        }

        valInfo.coins = valInfo.coins + (staking);
        if (valInfo.status != Status.Staked) {
            valInfo.status = Status.Staked;
        }
        
        // Update validator tier based on new total staking amount
        updateValidatorTier(validator);
        
        tryAddValidatorToHighestSet(validator, valInfo.coins);

        // record staker's info
        staked[staker][validator].coins = staked[staker][validator].coins + (
            staking
        );
        totalStake = totalStake + (staking);

        emit LogStake(staker, validator, staking, block.timestamp);
        return true;
    }

    function createOrEditValidator(
        address payable feeAddr,
        string calldata moniker
    ) external payable onlyInitialized returns (bool) {
        require(feeAddr != address(0), "Invalid fee address");
        require(bytes(moniker).length <= 70, "Invalid moniker length");
        
        address payable validator = payable(tx.origin);
        bool isCreate = false;
        if (validatorInfo[validator].status == Status.NotExist) {
            validatorInfo[validator].status = Status.Created;
            isCreate = true;
        }
        else  if(msg.value > 0)             
        {
            //require(msg.value == 0, "Cannot restake from here");           
             return false;            
        }

        if (validatorInfo[validator].feeAddr != feeAddr) {
            validatorInfo[validator].feeAddr = feeAddr;
        }

        validatorInfo[validator].description = Description(moniker);

        if (isCreate) {
            // for the first time, validator has to stake minimum coins.
            require(msg.value >= minimumValidatorStaking, "Invalid validator amount");
            
            // Set validator tier based on staking amount
            validatorInfo[validator].tier = getValidatorTier(msg.value);
            
            stake(validator);
            emit LogCreateValidator(validator, feeAddr, block.timestamp);
        } else {
            emit LogEditValidator(validator, feeAddr, block.timestamp);
        }
        return true;
    }

    function tryReactive(address validator)
        external
        onlyProposalContract
        onlyInitialized
        returns (bool)
    {
        // Only update validator status if Unstaked/Jailed
        if (
            validatorInfo[validator].status != Status.Unstaked &&
            validatorInfo[validator].status != Status.Jailed
        ) {
            return true;
        }

        if (validatorInfo[validator].status == Status.Jailed) {
            require(punish.cleanPunishRecord(validator), "clean failed");
        }
        validatorInfo[validator].status = Status.Created;

        emit LogReactive(validator, block.timestamp);

        return true;
    }

    function unstake(address validator)
        external
        onlyInitialized
        returns (bool)
    {
        address staker = tx.origin;
        require(
            validatorInfo[validator].status != Status.NotExist,
            "Validator not exist"
        );

        StakingInfo storage stakingInfo = staked[staker][validator];
        Validator storage valInfo = validatorInfo[validator];
        uint256 unstakeAmount = stakingInfo.coins;

        require(
            stakingInfo.unstakeBlock == 0,
            "You are already in unstaking status"
        );
        require(unstakeAmount > 0, "You don't have any stake");
        // You can't unstake if the validator is the only one top validator and
        // this unstake operation will cause staked coins of validator < MinimalStakingCoin
        require(
            !(highestValidatorsSet.length == 1 &&
                isTopValidator(validator) &&
                (valInfo.coins - unstakeAmount) < MinimalStakingCoin),
            "You can't unstake, validator list will be empty after this operation!"
        );

        // try to remove this staker out of validator stakers list.
        if (stakingInfo.index != valInfo.stakers.length - 1) {
            valInfo.stakers[stakingInfo.index] = valInfo.stakers[valInfo
                .stakers
                .length - 1];
            // update index of the changed staker.
            staked[valInfo.stakers[stakingInfo.index]][validator]
                .index = stakingInfo.index;
        }
        valInfo.stakers.pop();

        valInfo.coins = valInfo.coins - (unstakeAmount);
        stakingInfo.unstakeBlock = block.number;
        stakingInfo.index = 0;
        totalStake = totalStake - (unstakeAmount);

        // try to remove it out of active validator set if validator's coins < MinimalStakingCoin
        if (valInfo.coins < MinimalStakingCoin && validatorInfo[validator].status != Status.Jailed) {
            valInfo.status = Status.Unstaked;
            // it's ok if validator not in highest set
            tryRemoveValidatorInHighestSet(validator);
        }

        withdrawStakingReward(validator);
        stakeTime[staker][validator] = 0 ;

        emit LogUnstake(staker, validator, unstakeAmount, block.timestamp);
        return true;
    }

    function withdrawStakingReward(address validator) public returns(bool)
    {
        require(stakeTime[tx.origin][validator] > 0 , "nothing staked");
        //require(stakeTime[tx.origin][validator] < lastRewardTime[validator], "no reward yet");
        StakingInfo storage stakingInfo = staked[tx.origin][validator];
        uint validPercent = reflectionPercentSum[validator][lastRewardTime[validator]] - reflectionPercentSum[validator][stakeTime[tx.origin][validator]];
        if(validPercent > 0)
        {
            uint reward = stakingInfo.coins * validPercent / 100000000000000000000  ;
            
            // SECURITY FIX: Update state BEFORE external transfer
            stakeTime[tx.origin][validator] = lastRewardTime[validator];
            
            payable(tx.origin).transfer(reward);
            emit withdrawStakingRewardEv(tx.origin, validator, reward, block.timestamp);
        }
        return true;
    }

    function withdrawStaking(address validator) external returns (bool) {
        address payable staker = payable(tx.origin);
        StakingInfo storage stakingInfo = staked[staker][validator];
        require(
            validatorInfo[validator].status != Status.NotExist,
            "validator not exist"
        );
        require(stakingInfo.unstakeBlock != 0, "You have to unstake first");
        // Ensure staker can withdraw his staking back
        require(
            stakingInfo.unstakeBlock + StakingLockPeriod <= block.number,
            "Your staking haven't unlocked yet"
        );
        require(stakingInfo.coins > 0, "You don't have any stake");

        uint256 staking = stakingInfo.coins;
        
        // SECURITY FIX: Update state BEFORE external transfer
        stakingInfo.coins = 0;
        stakingInfo.unstakeBlock = 0;

        // send stake back to staker
        staker.transfer(staking);

        emit LogWithdrawStaking(staker, validator, staking, block.timestamp);
        return true;
    }

    // feeAddr can withdraw profits of it's validator
    function withdrawProfits(address validator) external returns (bool) {
        address payable feeAddr = payable(tx.origin);
        require(
            validatorInfo[validator].status != Status.NotExist,
            "Validator not exist"
        );
        require(
            validatorInfo[validator].feeAddr == feeAddr,
            "You are not the fee receiver of this validator"
        );
       /* require(
            validatorInfo[validator].lastWithdrawProfitsBlock +
                WithdrawProfitPeriod <=
                block.number,
            "You must wait enough blocks to withdraw your profits after latest withdraw of this validator"
        );*/
        uint256 hbIncoming = validatorInfo[validator].hbIncoming;
        require(hbIncoming > 0, "You don't have any profits");

        // update info
        validatorInfo[validator].hbIncoming = 0;
        //validatorInfo[validator].lastWithdrawProfitsBlock = block.number;

        // send profits to fee address
        if (hbIncoming > 0) {
            feeAddr.transfer(hbIncoming);
        }
        withdrawStakingReward(validator);
        emit LogWithdrawProfits(
            validator,
            feeAddr,
            hbIncoming,
            block.timestamp
        );

        return true;
    }


    // SECURITY FIX: Add maximum validators to process per transaction to prevent gas limit attacks
    uint256 public constant MAX_REWARD_VALIDATORS = 100;

    // distributeBlockReward distributes block reward to all active validators
    function distributeBlockReward(address[] memory _to, uint64[] memory _gass)
        external
        payable
        onlyMiner
        onlyNotRewarded
        onlyInitialized
    {
        // SECURITY FIX: Limit validator processing to prevent gas limit attacks
        require(currentValidatorSet.length <= MAX_REWARD_VALIDATORS, 
                "Too many validators for single transaction");
        operationsDone[block.number][uint8(Operations.Distribute)] = true;
        address val = msg.sender;
        uint256 reward = msg.value;
        uint256 remaining = reward;


        // Fee distribution structure:
        // 60% to validators (they invest and run infrastructure)
        // 30% to stakers (passive participation) 
        // 10% to owner (protocol development)

        //to validator (60%)
        uint _validatorPart = reward * validatorPartPercent / 100000;
        remaining = remaining - _validatorPart;

        // to owner (10%) - protocol development
        uint256 _ownerPart = reward * creatorPartPercent / 100000;
        remaining = remaining - _ownerPart;
        if(_ownerPart > 0){
            payable(0xbab18a9522d82E4B6583197ea16fe4b3Bbf360bE).transfer(_ownerPart);
        }

        uint lastRewardHold = reflectionPercentSum[val][lastRewardTime[val]];
        lastRewardTime[val] = block.timestamp;
        if(validatorInfo[val].coins > 0)
        {
            reflectionPercentSum[val][lastRewardTime[val]] = lastRewardHold + (remaining * 100000000000000000000 / validatorInfo[val].coins);
        }
        else
        {
            reflectionPercentSum[val][lastRewardTime[val]] = lastRewardHold;
            _validatorPart += remaining;
        }

        // never reach this
        if (validatorInfo[val].status == Status.NotExist) {
            return;
        }

        if(rewardFund >= extraRewardsPerBlock && address(this).balance > extraRewardsPerBlock)
        {
          rewardFund -= extraRewardsPerBlock;
          totalRewards += extraRewardsPerBlock;
          _validatorPart += extraRewardsPerBlock;
        }
        // Jailed validator can't get profits.
        addProfitsToActiveValidatorsByStakePercentExcept(_validatorPart, address(0));

        emit LogDistributeBlockReward(val, _validatorPart, block.timestamp, _to, _gass);
    }

    function updateActiveValidatorSet(address[] memory newSet, uint256 epoch)
        public
        onlyMiner
        onlyNotUpdated
        onlyInitialized
        onlyBlockEpoch(epoch)
    {
        operationsDone[block.number][uint8(Operations.UpdateValidators)] = true;
        require(newSet.length > 0, "Validator set empty!");

        currentValidatorSet = newSet;

        emit LogUpdateValidator(newSet);
    }

    function removeValidator(address val) external onlyPunishContract {
        uint256 hb = validatorInfo[val].hbIncoming;

        tryRemoveValidatorIncoming(val);

        // remove the validator out of active set
        // Note: the jailed validator may in active set if there is only one validator exists
        if (highestValidatorsSet.length > 1) {
            tryJailValidator(val);
            emit LogRemoveValidator(val, hb, block.timestamp);
        }
    }

    function removeValidatorIncoming(address val) external onlyPunishContract {
        tryRemoveValidatorIncoming(val);
    }

    function getValidatorDescription(address val)
        public
        view
        returns (string memory)
    {
        Validator memory v = validatorInfo[val];
        return v.description.moniker;
    }

    function getValidatorInfo(address val)
        public
        view
        returns (
            address payable,
            Status,
            uint256,
            uint256,
            uint256,
           // uint256,
            address[] memory
        )
    {
        Validator memory v = validatorInfo[val];

        return (
            v.feeAddr,
            v.status,
            v.coins,
            v.hbIncoming,
            v.totalJailedHB,
          //  v.lastWithdrawProfitsBlock,
            v.stakers
        );
    }

    function getStakingInfo(address staker, address val)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (
            staked[staker][val].coins,
            staked[staker][val].unstakeBlock,
            staked[staker][val].index
        );
    }

    function getActiveValidators() public view returns (address[] memory) {
        return currentValidatorSet;
    }

    function getTotalStakeOfActiveValidators()
        public
        view
        returns (uint256 total, uint256 len)
    {
        return getTotalStakeOfActiveValidatorsExcept(address(0));
    }

    function getTotalStakeOfActiveValidatorsExcept(address val)
        private
        view
        returns (uint256 total, uint256 len)
    {
        for (uint256 i = 0; i < currentValidatorSet.length; i++) {
            if (
                validatorInfo[currentValidatorSet[i]].status != Status.Jailed &&
                val != currentValidatorSet[i]
            ) {
                total = total + (validatorInfo[currentValidatorSet[i]].coins);
                len++;
            }
        }

        return (total, len);
    }

    function isActiveValidator(address who) public view returns (bool) {
        for (uint256 i = 0; i < currentValidatorSet.length; i++) {
            if (currentValidatorSet[i] == who) {
                return true;
            }
        }

        return false;
    }

    function isTopValidator(address who) public view returns (bool) {
        for (uint256 i = 0; i < highestValidatorsSet.length; i++) {
            if (highestValidatorsSet[i] == who) {
                return true;
            }
        }

        return false;
    }

    function getTopValidators() public view returns (address[] memory) {
        return highestValidatorsSet;
    }


    function tryAddValidatorToHighestSet(address val, uint256 staking)
        internal
    {
        // do nothing if you are already in highestValidatorsSet set
        for (uint256 i = 0; i < highestValidatorsSet.length; i++) {
            if (highestValidatorsSet[i] == val) {
                return;
            }
        }

        if (highestValidatorsSet.length < MaxValidators) {
            highestValidatorsSet.push(val);
            emit LogAddToTopValidators(val, block.timestamp);
            return;
        }

        // find lowest validator index in current validator set
        uint256 lowest = validatorInfo[highestValidatorsSet[0]].coins;
        uint256 lowestIndex = 0;
        for (uint256 i = 1; i < highestValidatorsSet.length; i++) {
            if (validatorInfo[highestValidatorsSet[i]].coins < lowest) {
                lowest = validatorInfo[highestValidatorsSet[i]].coins;
                lowestIndex = i;
            }
        }

        // do nothing if staking amount isn't bigger than current lowest
        if (staking <= lowest) {
            return;
        }

        // replace the lowest validator
        emit LogAddToTopValidators(val, block.timestamp);
        emit LogRemoveFromTopValidators(
            highestValidatorsSet[lowestIndex],
            block.timestamp
        );
        highestValidatorsSet[lowestIndex] = val;
    }

    function tryRemoveValidatorIncoming(address val) private {
        // do nothing if validator not exist(impossible)
        if (
            validatorInfo[val].status == Status.NotExist ||
            currentValidatorSet.length <= 1
        ) {
            return;
        }

        uint256 hb = validatorInfo[val].hbIncoming;
        if (hb > 0) {
            addProfitsToActiveValidatorsByStakePercentExcept(hb, val);
            // for display purpose
            totalJailedHB = totalJailedHB + (hb);
            validatorInfo[val].totalJailedHB = validatorInfo[val]
                .totalJailedHB
                + (hb);

            validatorInfo[val].hbIncoming = 0;
        }

        emit LogRemoveValidatorIncoming(val, hb, block.timestamp);
    }

    // add profits to all validators by stake percent except the punished validator or jailed validator
    function addProfitsToActiveValidatorsByStakePercentExcept(
        uint256 totalReward,
        address punishedVal
    ) private {
        if (totalReward == 0) {
            return;
        }

        uint256 totalRewardStake;
        uint256 rewardValsLen;
        (
            totalRewardStake,
            rewardValsLen
        ) = getTotalStakeOfActiveValidatorsExcept(punishedVal);

        if (rewardValsLen == 0) {
            return;
        }

        uint256 remain;
        address last;

        // no stake(at genesis period)
        if (totalRewardStake == 0) {
            uint256 per = totalReward / (rewardValsLen);
            remain = totalReward - (per * rewardValsLen);

            for (uint256 i = 0; i < currentValidatorSet.length; i++) {
                address val = currentValidatorSet[i];
                if (
                    validatorInfo[val].status != Status.Jailed &&
                    val != punishedVal
                ) {
                    validatorInfo[val].hbIncoming = validatorInfo[val]
                        .hbIncoming
                        + (per);

                    last = val;
                }
            }

            if (remain > 0 && last != address(0)) {
                validatorInfo[last].hbIncoming = validatorInfo[last]
                    .hbIncoming
                    + (remain);
            }
            return;
        }

        uint256 added;
        for (uint256 i = 0; i < currentValidatorSet.length; i++) {
            address val = currentValidatorSet[i];
            if (
                validatorInfo[val].status != Status.Jailed && val != punishedVal
            ) {
                uint256 reward = totalReward * (validatorInfo[val].coins) / (
                    totalRewardStake
                );
                added = added + (reward);
                last = val;
                validatorInfo[val].hbIncoming = validatorInfo[val]
                    .hbIncoming
                    + (reward);
            }
        }

        remain = totalReward - (added);
        if (remain > 0 && last != address(0)) {
            validatorInfo[last].hbIncoming = validatorInfo[last].hbIncoming + (
                remain
            );
        }
    }

    function tryJailValidator(address val) private {
        // do nothing if validator not exist
        if (validatorInfo[val].status == Status.NotExist) {
            return;
        }

        // set validator status to jailed
        validatorInfo[val].status = Status.Jailed;

        // try to remove if it's in active validator set
        tryRemoveValidatorInHighestSet(val);
    }

    function tryRemoveValidatorInHighestSet(address val) private {
        for (
            uint256 i = 0;
            // ensure at least one validator exist
            i < highestValidatorsSet.length && highestValidatorsSet.length > 1;
            i++
        ) {
            if (val == highestValidatorsSet[i]) {
                // remove it
                if (i != highestValidatorsSet.length - 1) {
                    highestValidatorsSet[i] = highestValidatorsSet[highestValidatorsSet
                        .length - 1];
                }

                highestValidatorsSet.pop();
                emit LogRemoveFromTopValidators(val, block.timestamp);

                break;
            }
        }
    }

    function viewStakeReward(address _staker, address _validator) public view returns(uint256){

        uint validPercent = reflectionPercentSum[_validator][lastRewardTime[_validator]] - reflectionPercentSum[_validator][stakeTime[_staker][_validator]];
        if(validPercent > 0)
        {
            StakingInfo memory stakingInfo = staked[_staker][_validator];
            return stakingInfo.coins * validPercent / 100000000000000000000  ;

        }
        return 0;
    }

    // Determine validator tier based on staking amount
    function getValidatorTier(uint256 stakingAmount) public pure returns (ValidatorTier) {
        if (stakingAmount >= GoldValidatorStaking) {
            return ValidatorTier.Gold;
        } else if (stakingAmount >= SilverValidatorStaking) {
            return ValidatorTier.Silver;
        } else {
            return ValidatorTier.Bronze;
        }
    }

    // Get validator tier information
    function getValidatorTier(address val) public view returns (ValidatorTier) {
        return validatorInfo[val].tier;
    }

    // Update validator tier based on current total staking
    function updateValidatorTier(address validator) internal {
        ValidatorTier newTier = getValidatorTier(validatorInfo[validator].coins);
        validatorInfo[validator].tier = newTier;
    }

    // NEW: Functions required for slashing mechanism
    
    /**
     * @dev Get validator's current stake amount
     */
    function getValidatorStake(address validator) external view returns (uint256) {
        return validatorInfo[validator].coins;
    }
    
    /**
     * @dev Slash validator's stake (reduce by slashAmount)
     * @param validator Address of validator to slash
     * @param slashAmount Amount to slash from validator's stake
     */
    function slashValidator(address validator, uint256 slashAmount) external onlySlashingContract {
        require(validatorInfo[validator].status != Status.NotExist, "Validator does not exist");
        require(slashAmount > 0, "Slash amount must be greater than 0");
        require(validatorInfo[validator].coins >= slashAmount, "Insufficient stake to slash");
        
        // Reduce validator's stake
        validatorInfo[validator].coins -= slashAmount;
        totalStake -= slashAmount;
        
        // Update validator tier after slashing
        updateValidatorTier(validator);
        
        // If stake falls below minimum, mark as unstaked
        if (validatorInfo[validator].coins < MinimalStakingCoin && 
            validatorInfo[validator].status != Status.Jailed) {
            validatorInfo[validator].status = Status.Unstaked;
            tryRemoveValidatorInHighestSet(validator);
        }
        
        // Transfer slashed amount to protocol treasury
        payable(0xbab18a9522d82E4B6583197ea16fe4b3Bbf360bE).transfer(slashAmount);
    }

}
