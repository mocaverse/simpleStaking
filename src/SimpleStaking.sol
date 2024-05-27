// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

//import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {SafeERC20, IERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import {Pausable} from "openzeppelin-contracts/contracts/utils/Pausable.sol";
import {Ownable2Step, Ownable} from  "openzeppelin-contracts/contracts/access/Ownable2Step.sol";


contract SimpleStaking {
    using SafeERC20 for IERC20;

    // interfaces 
    IERC20 internal immutable MOCA_TOKEN;
    
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
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);


    constructor(address mocaToken){
        
        MOCA_TOKEN = IERC20(mocaToken);
    }

    function stake(uint256 amount) external {

        // cache
        Data memory userData = _users[msg.sender];
        
        // update pool
        if(_totalStaked > 0){
            if(block.timestamp > _poolLastUpdateTimestamp){

                uint256 timeDelta = block.timestamp - _poolLastUpdateTimestamp;
                uint256 unbookedWeight = timeDelta * _totalStaked;

                _totalCumulativeWeight += unbookedWeight;
                _poolLastUpdateTimestamp = block.timestamp;
            }
        }
        
        // close the books
        if(userData.amount > 0){
            if(block.timestamp > userData.lastUpdateTimestamp){

                uint256 timeDelta = block.timestamp - userData.lastUpdateTimestamp;
                uint256 unbookedWeight = timeDelta * userData.amount;

                // update user
                userData.cumulativeWeight += unbookedWeight;
                userData.lastUpdateTimestamp = block.timestamp;
            }
        }

        // book new amount
        userData.amount += amount;
        _totalStaked += amount;

        // update storage
        _users[msg.sender] = userData;

        emit Staked(msg.sender, amount);
 
        // grab MOCA
        MOCA_TOKEN.safeTransferFrom(msg.sender, address(this), amount);
    }

    function unstake(uint256 amount) external {

        // cache
        Data memory userData = _users[msg.sender];

        // sanity checks
        require(userData.amount >= amount, "Insufficient user balance");

        // update pool
        if(_totalStaked > 0){
            if(block.timestamp > _poolLastUpdateTimestamp){

                uint256 timeDelta = block.timestamp - _poolLastUpdateTimestamp;
                uint256 unbookedWeight = timeDelta * _totalStaked;

                _totalCumulativeWeight += unbookedWeight;
                _poolLastUpdateTimestamp = block.timestamp;
            }
        }

        // close the books
        if(userData.amount > 0){
            if(block.timestamp > userData.lastUpdateTimestamp){

                uint256 timeDelta = block.timestamp - userData.lastUpdateTimestamp;
                uint256 unbookedWeight = timeDelta * userData.amount;

                // update user
                userData.cumulativeWeight += unbookedWeight;
                userData.lastUpdateTimestamp = block.timestamp;
            }
        }

        // book outflow
        userData.amount -= amount;
        _totalStaked -= amount;

        // update state 
        _users[msg.sender] = userData;

        emit Unstaked(msg.sender, amount);

        // transfer moca
        MOCA_TOKEN.safeTransfer(msg.sender, amount);
    }

    //------ getters ------

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

    function getAddressTimeWeight(address user) external view returns(uint256) {
        // cache
        Data memory userData = _users[user];

        // calc. unbooked
        if(block.timestamp > userData.lastUpdateTimestamp){

            uint256 timeDelta = block.timestamp - userData.lastUpdateTimestamp;

            uint256 unbookedWeight = userData.amount * timeDelta;
            return (userData.cumulativeWeight + unbookedWeight);
        }

        // updated to latest, nothing unbooked 
        return userData.cumulativeWeight;
    }

    function getPoolTimeWeight() external view returns(uint256) {
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
