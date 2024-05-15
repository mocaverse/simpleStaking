// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

//import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {SafeERC20, IERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import {Pausable} from "openzeppelin-contracts/contracts/utils/Pausable.sol";
import {Ownable2Step, Ownable} from  "openzeppelin-contracts/contracts/access/Ownable2Step.sol";

import {IREALMID} from "./IRealmId.sol";

/**
 note:
  - is there an end time?

 */
contract SimpleStaking {
    using SafeERC20 for IERC20;

    // interfaces 
    IERC20 public MOCA_TOKEN;
    IREALMID public REALM_ID;

    struct Data {
        uint256 amount;
        uint256 timeWeighted;
        uint256 lastUpdateTimestamp;
    }

    mapping(uint256 id => Data idData) public ids;
    mapping(address user => mapping (uint256 id => Data userData)) public users;

    // events 
    event Staked(address indexed user, uint256 indexed id, uint256 amount);
    event Unstaked(address indexed user, uint256 indexed id, uint256 amount);


    constructor(address mocaToken, address realmId){
        
        MOCA_TOKEN = IERC20(mocaToken);
        REALM_ID = IREALMID(realmId);
    }

    function stake(uint256 id, uint256 amount) external {

        // check if id exists: reverts if owner == address(0)
        REALM_ID.ownerOf(id);

        // cache
        Data memory idData = ids[id];
        Data memory userData = users[msg.sender][id];

        // close the books
        if(idData.amount > 0) {
            if(idData.lastUpdateTimestamp < block.timestamp) {
                uint256 timeDelta = block.timestamp - idData.lastUpdateTimestamp;
                
                idData.timeWeighted += timeDelta * idData.amount;
                idData.lastUpdateTimestamp = block.timestamp;
            }
        }
        
        if(userData.amount > 0){
            if(userData.lastUpdateTimestamp < block.timestamp){
                uint256 timeDelta = block.timestamp - userData.lastUpdateTimestamp;

                userData.timeWeighted += timeDelta * userData.amount;
                userData.lastUpdateTimestamp = block.timestamp;
            }
        }

        // book new amount
        idData.amount += amount;
        userData.amount += amount;

        // update storage
        ids[id] = idData;
        users[msg.sender][id] = userData;

        emit Staked(msg.sender, id, amount);
 
        // grab MOCA
        MOCA_TOKEN.safeTransferFrom(msg.sender, address(this), amount);
    }

    function unstake(uint256 id, uint256 amount) external {

        // check if id exists: reverts if owner == address(0)
        REALM_ID.ownerOf(id);

        // cache
        Data memory idData = ids[id];
        Data memory userData = users[msg.sender][id];

        // sanity checks
        require(userData.amount >= amount, "Insufficient user balance");
        require(idData.amount >= amount, "Insufficient id balance");

        // close the books
        if(idData.amount > 0) {
            if(idData.lastUpdateTimestamp < block.timestamp) {
                //uint256 currentTimestamp = block.timestamp > endTime ? endTime : block.timestamp;
                uint256 timeDelta = block.timestamp - idData.lastUpdateTimestamp;
                
                idData.timeWeighted += timeDelta * idData.amount;
                idData.lastUpdateTimestamp = block.timestamp;
            }
        }
        
        if(userData.amount > 0){
            if(userData.lastUpdateTimestamp < block.timestamp){

                uint256 timeDelta = block.timestamp - userData.lastUpdateTimestamp;

                userData.timeWeighted += timeDelta * userData.amount;
                userData.lastUpdateTimestamp = block.timestamp;
            }
        }

        // book outflow
        idData.amount -= amount;
        userData.amount -= amount;

        // update state 
        ids[id] = idData;
        users[msg.sender][id] = userData;


        emit Unstaked(msg.sender, id, amount);

        // transfer moca
        MOCA_TOKEN.safeTransfer(msg.sender, amount);
    }


    function getIdTotalTimeWeight(uint256 id) external view returns(uint256) {
        // cache
        Data memory idData = ids[id];

        // calc. unbooked 
        if(idData.lastUpdateTimestamp < block.timestamp) {

            uint256 unbookedWeight = idData.amount * (block.timestamp - idData.lastUpdateTimestamp);
            return (idData.timeWeighted + unbookedWeight);
        }

        // updated to latest, nothing unbooked 
        return idData.timeWeighted;
    }

    function getAddressTimeWeight(uint256 id, address user) external view returns(uint256) {
        // cache
        Data memory userData = users[user][id];

        // calc. unbooked 
        if(userData.lastUpdateTimestamp < block.timestamp) {

            uint256 unbookedWeight = userData.amount * (block.timestamp - userData.lastUpdateTimestamp);
            return (userData.timeWeighted + unbookedWeight);
        }

        // updated to latest, nothing unbooked 
        return userData.timeWeighted;
    }
}
