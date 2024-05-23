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
    event Staked(address indexed user, uint256 amount);
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
        
    }

}


contract StateZeroTest is StateZero {

    function testUserCanStake() public {
        // allowance
        vm.prank(userA);
        mocaToken.approve(address(pool), userATokens);

        // check events
        vm.expectEmit(true, true, false, false);
        emit Staked(userA, userATokens);

        vm.prank(userA);
        pool.stake(userATokens);

        assertEq(mocaToken.balanceOf(userA), 0);
        assertEq(mocaToken.balanceOf(address(pool)), userATokens);

        // get user data
        (uint256 amount, uint256 timeWeighted, uint256 lastUpdateTimestamp) = pool.users(userA);
        
        assertEq(amount, userATokens);
        assertEq(timeWeighted, 0);
        assertEq(lastUpdateTimestamp, 0);
    }

}


abstract contract StateStaked is StateZero {

    function setUp() public virtual override {
        super.setUp();

        vm.warp(1);

        vm.startPrank(userA);
        
        mocaToken.approve(address(pool), userATokens);

        pool.stake(userATokens);

        vm.stopPrank();
    }
}

contract StateStakedTest is StateStaked {

    function testUserCanUnstake() public {
        
        vm.prank(userA);
        pool.unstake(userATokens);

        assertEq(mocaToken.balanceOf(userA), userATokens);
        assertEq(mocaToken.balanceOf(address(pool)), 0);

        // get user data
        (uint256 amount, uint256 timeWeighted, uint256 lastUpdateTimestamp) = pool.users(userA);
        
        assertEq(amount, 0);
        assertEq(timeWeighted, (userATokens * 1));
        assertEq(lastUpdateTimestamp, 1);
    }
}

//note: check timeweight after 10 seconds
abstract contract StateStakedT10 is StateStaked {

    function setUp() public virtual override {
        super.setUp();

        vm.warp(10);
    }
}


contract StateStakedT10Test is StateStakedT10 {
    
    function testTimeWeightCalculation() public {

        uint256 timeWeightGetter = pool.getAddressTimeWeight(userA);

        //calc.
        uint256 timeDelta = 10 - 0;
        uint256 timeWeightCalc = timeDelta * userATokens;

        assertEq(timeWeightGetter, timeWeightCalc);

        // exec. state transition
        vm.prank(userA);
        pool.unstake(userATokens);

        // get user data
        (uint256 amount, uint256 timeWeightedStored, uint256 lastUpdateTimestamp) = pool.users(userA);
        
        assertEq(amount, 0);
        assertEq(timeWeightedStored, (userATokens * 10));
        assertEq(lastUpdateTimestamp, 10);

        assertEq(timeWeightedStored, timeWeightCalc);
        
    }
}