// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {SafeERC20, IERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable2Step, Ownable} from "./../lib/openzeppelin-contracts/contracts/access/Ownable2Step.sol";

contract SimpleStaking is Ownable2Step {
    using SafeERC20 for IERC20;

    // interfaces 
    IERC20 internal immutable MOCA_TOKEN;
    // startTime
    uint256 internal immutable _startTime;

    // pool data 
    uint256 internal _totalStaked;
    uint256 internal _totalCumulativeWeight;
    uint256 internal _poolLastUpdateTimestamp; //note: should 128 for packing?

    struct Data {
        uint256 amount;
        uint256 cumulativeWeight;
        uint256 lastUpdateTimestamp;
    }

    mapping(address user => Data userData) internal _users;

    // events 
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event StakedBehalf(address[] indexed users, uint256[] indexed amounts);


    constructor(address mocaToken, uint256 startTime_, address owner) Ownable(owner){
        // 1722384000: 31/07/24 12:00am UTC
        require(startTime_ < 1722384000, "Far-dated startTime");        

        MOCA_TOKEN = IERC20(mocaToken);
        
        _startTime = startTime_;
    }


    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice User to stake MocaTokens
     * @dev User can stake for another address of choice
     * @param amount Tokens to stake, 1e8 precision
     */
    function stake(uint256 amount) external {
        require(amount > 0, "Zero amount");

        // cache
        Data memory userData_ = _users[msg.sender];
   
        // book pool's previous
        _updatePool();

        // book user's previous
        Data memory userData = _updateUserCumulativeWeight(userData_);
    
        // book inflow
        userData.amount += amount;
        _totalStaked += amount;

        // user: update storage
        _users[msg.sender] = userData;

        emit Staked(msg.sender, amount);
 
        // grab MOCA
        MOCA_TOKEN.safeTransferFrom(msg.sender, address(this), amount);
    }

    /**
     * @notice User to unstake MocaTokens
     * @param amount Tokens to unstake, 1e8 precision
     */
    function unstake(uint256 amount) external {
        require(amount > 0, "Zero amount");

        // cache
        Data memory userData_ = _users[msg.sender];

        // sanity checks
        require(userData_.amount >= amount, "Insufficient balance");

        // book pool's previous
        _updatePool();

        // book user's previous
        Data memory userData = _updateUserCumulativeWeight(userData_);

        // book outflow
        userData.amount -= amount;
        _totalStaked -= amount;      // sstore 

        // user: update state 
        _users[msg.sender] = userData;

        emit Unstaked(msg.sender, amount);

        // transfer moca
        MOCA_TOKEN.safeTransfer(msg.sender, amount);
    }

    /**
     * @notice Owner to stake on behalf of users for distribution
     * @dev Max array length: 5
     * @param users Array of address 
     * @param amounts Array of stake amounts, 1e18 precision
     */
    function stakeBehalf(address[] memory users, uint256[] memory amounts) external onlyOwner {
        uint256 usersLength = users.length;
        uint256 amountLength = amounts.length;
        require(usersLength == amountLength, "Incorrect lengths");

        require(usersLength > 0, "Empty array");
        require(usersLength <= 10, "Array max length exceeded");

        // book pool's previous
        _updatePool();

        uint256 totalAmount;
        for (uint256 i; i < usersLength; ++i){
            address onBehalfOf = users[i];
            uint256 amount = amounts[i];

            // cache
            Data memory userData_ = _users[onBehalfOf];
        
            // book user's previous
            Data memory userData = _updateUserCumulativeWeight(userData_);

            // book inflow
            userData.amount += amount;
            _totalStaked += amount;         //sstore

            // user: update storage
            _users[onBehalfOf] = userData;

            // increment totalAmount
            totalAmount += amount;
        }
        
        emit StakedBehalf(users, amounts);

        // grab MOCA
        MOCA_TOKEN.safeTransferFrom(msg.sender, address(this), totalAmount);
    }


    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _updatePool() internal {

        if(_totalStaked > 0){
            if(block.timestamp > _poolLastUpdateTimestamp){

                uint256 timeDelta = _getTimeDelta(block.timestamp, _poolLastUpdateTimestamp);
                uint256 unbookedWeight = timeDelta * _totalStaked;
                
                // sstore
                _totalCumulativeWeight += unbookedWeight;
            }
        }
        
        // sstore
        _poolLastUpdateTimestamp = block.timestamp;
    }

    function _updateUserCumulativeWeight(Data memory userData) internal returns(Data memory) {
        
        // staking not started: return early
        uint256 startTime = _startTime;
        if (block.timestamp <= startTime) {

            userData.lastUpdateTimestamp = block.timestamp;  
            return userData;
        }

        // staking has begun
        if(userData.amount > 0){
            if(block.timestamp > userData.lastUpdateTimestamp){
                
                // timeDelta: 0 if staking has not begun 
                uint256 timeDelta = _getTimeDelta(block.timestamp, userData.lastUpdateTimestamp);
                uint256 unbookedWeight = timeDelta * userData.amount;

                // update user
                userData.cumulativeWeight += unbookedWeight;
            }
        }
        
        userData.lastUpdateTimestamp = block.timestamp;
        return userData;
    }

    function _getTimeDelta(uint256 to, uint256 from) internal view returns (uint256) {
        // cache
        uint256 startTime = _startTime;
        
        if(from < startTime){
            from = startTime;
        }

        return (to - from);
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    ///@notice returns moca token address    
    function getMocaToken() external view returns(address) {
        return address(MOCA_TOKEN);
    }

    ///@notice returns _startTime
    function getStartTime() external view returns(uint256) {
        return _startTime;
    }

    ///@notice returns _totalStaked
    function getTotalStaked() external view returns(uint256) {
        return _totalStaked;
    }

    ///@notice returns _totalCumulativeWeight
    function getTotalCumulativeWeight() external view returns(uint256) {
        return _totalCumulativeWeight;
    }

    ///@notice returns _poolLastUpdateTimestamp
    function getPoolLastUpdateTimestamp() external view returns(uint256) {
        return _poolLastUpdateTimestamp;
    }

    ///@notice returns user data struct
    function getUser(address user) external view returns(Data memory) {
        return _users[user];
    } 

    ///@notice returns user's cumulative weight
    function getUserCumulativeWeight(address user) external view returns(uint256) {
        // cache
        Data memory userData = _users[user];

        // calc. unbooked
        if(userData.amount > 0) {
            if(block.timestamp > userData.lastUpdateTimestamp){

                uint256 timeDelta = _getTimeDelta(block.timestamp, userData.lastUpdateTimestamp);

                uint256 unbookedWeight = userData.amount * timeDelta;
                return (userData.cumulativeWeight + unbookedWeight);
            }
        }

        // updated to latest, nothing unbooked 
        return userData.cumulativeWeight;
    }

    ///@notice returns pool's total cumulative weight (incl. pending)
    function getPoolCumulativeWeight() external view returns(uint256) {
        // calc. unbooked
        if(block.timestamp > _poolLastUpdateTimestamp){

            uint256 timeDelta = _getTimeDelta(block.timestamp, _poolLastUpdateTimestamp);

            uint256 unbookedWeight = _totalStaked * timeDelta;
            return (_totalCumulativeWeight + unbookedWeight);
        }

        // updated to latest, nothing unbooked 
        return _totalCumulativeWeight;
    }
}



