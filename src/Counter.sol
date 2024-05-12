// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

contract SimpleStaking {

    IERC20 public MOCA_TOKEN;

    struct Data {
        uint256 amount;
        uint256 timeWeighted;
        uint256 lastUpdateTimestamp;
    }

    mapping(address user => mapping (bytes32 id => Data userData)) public users;
    //mapping(bytes32 id => uint256 balance) public balances;
    mapping(bytes32 id => Data idData) public balances;

    constructor(){}

    function stake(bytes32 id, uint256 amount) external {
        require(id != bytes32(0), "Invalid id");


    }

    function unstake(bytes32 id, uint256 amount) external {}

    //function unstakeAll() external {}
    

}
