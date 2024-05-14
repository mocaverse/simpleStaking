// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

//import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {SafeERC20, IERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import {Pausable} from "openzeppelin-contracts/contracts/utils/Pausable.sol";
import {Ownable2Step, Ownable} from  "openzeppelin-contracts/contracts/access/Ownable2Step.sol";

/**
 note:
  - is there an end time?

 */
contract SimpleStaking {
    using SafeERC20 for IERC20;

    IERC20 public MOCA_TOKEN;
    IREALMID public REALM_ID;

    struct Data {
        uint256 amount;
        uint256 timeWeighted;
        uint256 lastUpdateTimestamp;
    }

    mapping(address user => mapping (bytes32 id => Data userData)) public users;
    //mapping(bytes32 id => uint256 balance) public balances;
    mapping(bytes32 id => Data idData) public ids;

    
    event Staked(address indexed user, bytes32 indexed id, uint256 amount);
    event Unstaked(address indexed user, bytes32 indexed id, uint256 amount);


    constructor(address mocaToken){
        
        MOCA_TOKEN = IERC20(mocaToken);
    }

    function stake(bytes32 id, uint256 amount) external {
        require(id != bytes32(0), "Invalid id");
        
        // check if id exists: reverts if owner == address(0)
        realmIdContract.ownerOf(realmId);

        // cache
        Data memory idData = ids[id];
        Data memory userData = users[msg.sender][id];

        // close the books
        if(idData.amount > 0) {
            if(idData.lastUpdateTimestamp > block.timestamp) {
                //uint256 currentTimestamp = block.timestamp > endTime ? endTime : block.timestamp;
                uint256 timeDelta = block.timestamp - idData.lastUpdateTimestamp;
                
                idData.timeWeighted += timeDelta * idData.amount;
            }
        }
        
        if(userData.amount > 0){
            if(userData.lastUpdateTimestamp > block.timestamp){

                uint256 timeDelta = block.timestamp - userData.lastUpdateTimestamp;
                userData.timeWeighted += timeDelta * userData.amount;
            }
        }

        // book new amount
        idData.amount += amount;
        userData.amount += amount;

        emit Staked(msg.sender, id, amount);
 
        // grab MOCA
        MOCA_TOKEN.safeTransferFrom(msg.sender, address(this), amount);
    }

    function unstake(bytes32 id, uint256 amount) external {
        require(id != bytes32(0), "Invalid id");

        // check if id exists: reverts if owner == address(0)
        realmIdContract.ownerOf(realmId);

        // cache
        Data memory idData = ids[id];
        Data memory userData = users[msg.sender][id];

        // sanity checks
        require(userData.amount >= amount, "Insufficient user balance");
        require(idData.amount >= amount, "Insufficient id balance");

        // close the books
        if(idData.amount > 0) {
            if(idData.lastUpdateTimestamp > block.timestamp) {
                //uint256 currentTimestamp = block.timestamp > endTime ? endTime : block.timestamp;
                uint256 timeDelta = block.timestamp - idData.lastUpdateTimestamp;
                
                idData.timeWeighted += timeDelta * idData.amount;
            }
        }
        
        if(userData.amount > 0){
            if(userData.lastUpdateTimestamp > block.timestamp){

                uint256 timeDelta = block.timestamp - userData.lastUpdateTimestamp;
                userData.timeWeighted += timeDelta * userData.amount;
            }
        }

        // book outflow
        idData.amount -= amount;
        userData.amount -= amount;

        emit Unstaked(msg.sender, id, amount);

        // transfer moca
        MOCA_TOKEN.safeTransfer(msg.sender, amount);
    }


    function getIdTotalTimeWeight(bytes32 id) external view {
        // cache
        Data memory id = ids[id];

        // nothing staked, nothing gained 
        if(id.amount == 0) return 0;

        // calc. unbooked 
        if(id.lastUpdateTimestamp > block.timestamp) {

            uint256 unbookedWeight = id.amount * (block.timestamp - id.lastUpdateTimestamp);
            return (id.timeWeighted + unbookedWeight);
        }

        // updated to latest, nothing unbooked 
        return id.timeWeighted;
    }

    function getAddressTimeWeight(bytes32 id, address user) external view {
        // cache
        Data memory userData = users[user][id];

        // nothing staked, nothing gained 
        if(id.amount == 0) return 0;

        // calc. unbooked 
        if(id.lastUpdateTimestamp > block.timestamp) {

            uint256 unbookedWeight = id.amount * (block.timestamp - id.lastUpdateTimestamp);
            return (id.timeWeighted + unbookedWeight);
        }

        // updated to latest, nothing unbooked 
        return id.timeWeighted;
    }
}
