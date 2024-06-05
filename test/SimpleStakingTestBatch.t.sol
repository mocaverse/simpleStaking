// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SimpleStaking} from "../src/SimpleStaking.sol";

import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

abstract contract StateZero is Test {

    SimpleStaking public pool;
    ERC20Mock public mocaToken;

    address public userA;
    address public userB;
    address public userC;
    address public owner;

    uint256 public userATokens;
    uint256 public userBTokens;
    uint256 public userCTokens;

    // events 
    event Staked(address indexed onBehalfOf, address indexed msgSender, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);

    function setUp() public virtual {
    
        // users
        userA = makeAddr("userA");
        userB = makeAddr("userB");
        userC = makeAddr("userC");
        owner = makeAddr("owner");

        // values
        userATokens = 20 ether;
        userBTokens = 50 ether;
        userCTokens = 80 ether;

        //contracts
        mocaToken = new ERC20Mock();    
        pool = new SimpleStaking(address(mocaToken));

        // mint tokens
        mocaToken.mint(userA, userATokens);
        mocaToken.mint(userB, userBTokens);
        mocaToken.mint(userC, userCTokens);

        // allowance
        vm.prank(userA);
        mocaToken.approve(address(pool), userATokens);

        vm.prank(userB);
        mocaToken.approve(address(pool), userBTokens);

        // set time
        vm.warp(0);
    }

}


contract StateZeroTest is StateZero {

    function testUserCannotUnstake() public {
        vm.prank(userA);
        vm.expectRevert("Insufficient user balance");
        pool.unstake(userATokens);
    }

    function testUserCanStake(address someUser) public {

        // check events
        vm.expectEmit(true, true, false, false);
        emit Staked(someUser, userA, userATokens);

        vm.prank(userA);
        pool.stake(someUser, userATokens);

        assertEq(mocaToken.balanceOf(userA), 0);
        assertEq(mocaToken.balanceOf(address(pool)), userATokens);

        // get user data
        SimpleStaking.Data memory userData = pool.getUser(someUser);
        
        assertEq(userData.amount, userATokens);
        assertEq(userData.cumulativeWeight, 0);
        assertEq(userData.lastUpdateTimestamp, 0);

        // get pool data
        assertEq(pool.getPoolLastUpdateTimestamp(), userData.lastUpdateTimestamp);
        assertEq(pool.getTotalStaked(), userData.amount);
    }

    function testTokenGetter() public {
       address token = pool.getMocaToken();
       assert(address(mocaToken) == token);
    }

    function testGetTotalStakedDoesNotChangeOnDirectTransfer() public {
        vm.prank(userA);
        mocaToken.transfer(address(pool), userATokens);

        assertEq(pool.getTotalStaked(), 0);
    }
}