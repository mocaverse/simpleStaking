// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {SafeERC20, IERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract SimpleStaking {
    using SafeERC20 for IERC20;

    // interfaces 
    IERC20 internal immutable MOCA_TOKEN;
    // startTime
    uint256 internal immutable _startTime;

    // pool data
    uint256 internal _totalStaked;
    uint256 internal _totalCumulativeWeight;
    uint256 internal _poolLastUpdateTimestamp;

    struct Data {
        uint256 amount;
        uint256 cumulativeWeight;
        uint256 lastUpdateTimestamp;
    }

    mapping(address user => Data userData) internal _users;

    // events 
    event Staked(address indexed onBehalfOf, address indexed msgSender, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event StakedBehalf(address[] indexed users, uint256[] amounts);


    constructor(address mocaToken, uint256 startTime_){
        
        MOCA_TOKEN = IERC20(mocaToken);
        _startTime = startTime_;
    }


    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/

    function stake(address onBehalfOf, uint256 amount) external {
        require(_startTime <= block.timestamp, "Not started");
        require(amount > 0, "Invalid amount");

        // cache
        Data memory userData_ = _users[onBehalfOf];
        
        // book pool's previous
        _updatePool();

        // book user's previous
        Data memory userData = _updateUserCumulativeWeight(userData_);

        // book inflow
        userData.amount += amount;
        _totalStaked += amount;

        // user: update storage
        _users[onBehalfOf] = userData;

        emit Staked(onBehalfOf, msg.sender, amount);
 
        // grab MOCA
        MOCA_TOKEN.safeTransferFrom(msg.sender, address(this), amount);
    }

    function unstake(uint256 amount) external {
        require(_startTime <= block.timestamp, "Not started");
        require(amount > 0, "Invalid amount");

        // cache
        Data memory userData_ = _users[msg.sender];

        // sanity checks
        require(userData_.amount >= amount, "Insufficient user balance");

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

    function stakeBehalf(address[] memory users, uint256[] memory amounts) external {
        uint256 length = users.length;
        require(length > 0, "Empty array");
        require(length <= 5, "Array max length exceeded");

        for (uint256 i; i < length; ++i){
            address onBehalfOf = users[i];
            uint256 amount = amounts[i];

            // cache
            Data memory userData_ = _users[onBehalfOf];
        
            // book pool's previous
            _updatePool();
        
            // book user's previous
            Data memory userData = _updateUserCumulativeWeight(userData_);

            // book inflow
            userData.amount += amount;
            _totalStaked += amount;         //sstore

            // user: update storage
            _users[onBehalfOf] = userData;
        }
        
        event StakedBehalf(address[] users, uint256[] amounts);
    }


    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _updatePool() internal {

        if(_totalStaked > 0){
            if(block.timestamp > _poolLastUpdateTimestamp){

                uint256 timeDelta = block.timestamp - _poolLastUpdateTimestamp;
                uint256 unbookedWeight = timeDelta * _totalStaked;

                _totalCumulativeWeight += unbookedWeight;
            }
        }

        _poolLastUpdateTimestamp = block.timestamp;
    }

    function _updateUserCumulativeWeight(Data memory userData) internal returns(Data memory) {

        if(userData.amount > 0){
            if(block.timestamp > userData.lastUpdateTimestamp){

                uint256 timeDelta = block.timestamp - userData.lastUpdateTimestamp;
                uint256 unbookedWeight = timeDelta * userData.amount;

                // update user
                userData.cumulativeWeight += unbookedWeight;
            }
        }

        userData.lastUpdateTimestamp = block.timestamp;
        return userData;
    }


    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    function getUser(address user) external view returns(Data memory) {
        return _users[user];
    } 

    function getTotalStaked() external view returns(uint256) {
        return _totalStaked;
    }

    function getTotalCumulativeWeight() external view returns(uint256) {
        return _totalCumulativeWeight;
    }

    function getPoolLastUpdateTimestamp() external view returns(uint256) {
        return _poolLastUpdateTimestamp;
    }

    function getMocaToken() external view returns(address) {
        return address(MOCA_TOKEN);
    }

    function getUserCumulativeWeight(address user) external view returns(uint256) {
        // cache
        Data memory userData = _users[user];

        // calc. unbooked
        if(userData.amount > 0) {
            if(block.timestamp > userData.lastUpdateTimestamp){

                uint256 timeDelta = block.timestamp - userData.lastUpdateTimestamp;

                uint256 unbookedWeight = userData.amount * timeDelta;
                return (userData.cumulativeWeight + unbookedWeight);
            }
        }

        // updated to latest, nothing unbooked 
        return userData.cumulativeWeight;
    }

    function getPoolCumulativeWeight() external view returns(uint256) {
        // calc. unbooked
        if(block.timestamp > _poolLastUpdateTimestamp){

            uint256 timeDelta = block.timestamp - _poolLastUpdateTimestamp;

            uint256 unbookedWeight = _totalStaked * timeDelta;
            return (_totalCumulativeWeight + unbookedWeight);
        }

        // updated to latest, nothing unbooked 
        return _totalCumulativeWeight;
    }
}
