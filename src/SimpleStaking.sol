// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

//import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {SafeERC20, IERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import {Pausable} from "openzeppelin-contracts/contracts/utils/Pausable.sol";
import {Ownable2Step, Ownable} from  "openzeppelin-contracts/contracts/access/Ownable2Step.sol";


contract SimpleStaking {
    using SafeERC20 for IERC20;

    // interfaces 
    IERC20 public MOCA_TOKEN;

    struct Data {
        uint256 amount;
        uint256 timeWeighted;
        uint256 lastUpdateTimestamp;
    }

    mapping(address user => Data userData) public users;

    // events 
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);


    constructor(address mocaToken){
        
        MOCA_TOKEN = IERC20(mocaToken);
    }

    function stake(uint256 amount) external {

        // cache
        Data memory userData = users[msg.sender];
        
        // close the books
        if(userData.amount > 0){
            if(block.timestamp > userData.lastUpdateTimestamp){

                uint256 timeDelta = block.timestamp - userData.lastUpdateTimestamp;

                // update
                userData.timeWeighted += timeDelta * userData.amount;
                userData.lastUpdateTimestamp = block.timestamp;
            }
        }

        // book new amount
        userData.amount += amount;

        // update storage
        users[msg.sender] = userData;

        emit Staked(msg.sender, amount);
 
        // grab MOCA
        MOCA_TOKEN.safeTransferFrom(msg.sender, address(this), amount);
    }

    function unstake(uint256 amount) external {

        // cache
        Data memory userData = users[msg.sender];

        // sanity checks
        require(userData.amount >= amount, "Insufficient user balance");

        // close the books
        if(userData.amount > 0){
            if(block.timestamp > userData.lastUpdateTimestamp){

                uint256 timeDelta = block.timestamp - userData.lastUpdateTimestamp;
                
                // update
                userData.timeWeighted += timeDelta * userData.amount;
                userData.lastUpdateTimestamp = block.timestamp;
            }
        }

        // book outflow
        userData.amount -= amount;

        // update state 
        users[msg.sender] = userData;

        emit Unstaked(msg.sender, amount);

        // transfer moca
        MOCA_TOKEN.safeTransfer(msg.sender, amount);
    }

    function getAddressTimeWeight(address user) external view returns(uint256) {
        // cache
        Data memory userData = users[user];

        // calc. unbooked `
        if(block.timestamp > userData.lastUpdateTimestamp){

            uint256 timeDelta = block.timestamp - userData.lastUpdateTimestamp;

            uint256 unbookedWeight = userData.amount * timeDelta;
            return (userData.timeWeighted + unbookedWeight);
        }

        // updated to latest, nothing unbooked 
        return userData.timeWeighted;
    }
}
