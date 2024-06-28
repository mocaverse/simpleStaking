// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SimpleStaking} from "../src/SimpleStaking.sol";

import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import {Pausable} from "./../lib/openzeppelin-contracts/contracts/utils/Pausable.sol";

abstract contract StateZero is Test {

    SimpleStaking public pool;
    ERC20Mock public mocaToken;

    address public userA;
    address public userB;
    address public userC;
    address public owner;
    address public updater;

    uint256 public userATokens;
    uint256 public userBTokens;
    uint256 public userCTokens;
    uint256 public ownerTokens;
    uint256 public updaterTokens;

    uint256 public startTime;

    // events 
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event StakedBehalf(address[] indexed users, uint256[] indexed amounts);

    function setUp() public virtual {
    
        // users
        userA = makeAddr("userA");
        userB = makeAddr("userB");
        userC = makeAddr("userC");
        owner = makeAddr("owner");
        updater = makeAddr("updater");

        // values
        userATokens = 20 ether;
        userBTokens = 50 ether;
        userCTokens = 80 ether;
        ownerTokens = 50 ether;
        updaterTokens = 50 ether;

        //contracts
        mocaToken = new ERC20Mock();    





        
    }
}


contract StateZeroTest is StateZero {

    function testDeployFarStartDate() public {
        
        //check: far start time
        startTime = block.timestamp + 60 days;

        vm.expectRevert("Far-dated start");
        pool = new SimpleStaking(address(mocaToken), startTime, owner, updater);
    }

    function testDeployStaleStartDate() public {
        
        //check: stale start time 
        startTime = 0;
        vm.warp(10);

        vm.expectRevert("StartTime in past");
        pool = new SimpleStaking(address(mocaToken), startTime, owner, updater);
    }
}
