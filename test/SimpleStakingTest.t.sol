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

    function testUserCannotUnstake() public {
        vm.prank(userA);
        vm.expectRevert("Insufficient user balance");
        pool.unstake(userATokens);
    }

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
        SimpleStaking.Data memory userData = pool.getUser(userA);
        
        assertEq(userData.amount, userATokens);
        assertEq(userData.cumulativeWeight, 0);
        assertEq(userData.lastUpdateTimestamp, 0);
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
        SimpleStaking.Data memory userData = pool.getUser(userA);
        
        assertEq(userData.amount, 0);
        assertEq(userData.cumulativeWeight, (userATokens * 1));
        assertEq(userData.lastUpdateTimestamp, 1);
    }
}

//note: check timeweight after 10 seconds
abstract contract StateStakedT10 is StateStaked {

    function setUp() public virtual override {
        super.setUp();

        vm.warp(10);

        vm.startPrank(userB);
        
        mocaToken.approve(address(pool), userBTokens);
        pool.stake(userBTokens);

        vm.stopPrank();
    }
}


contract StateStakedT10Test is StateStakedT10 {
    
    function testUserTimeWeightCalculation() public {

        uint256 cumulativeWeightGetter = pool.getAddressTimeWeight(userA);

        //calc.
        uint256 timeDelta = 10 - 0;
        uint256 cumulativeWeightCalc = timeDelta * userATokens;

        assertEq(cumulativeWeightGetter, cumulativeWeightCalc);

        // exec. state transition
        vm.prank(userA);
        pool.unstake(userATokens);

        // get user data
        SimpleStaking.Data memory userData = pool.getUser(userA);
        
        assertEq(userData.amount, 0);
        assertEq(userData.cumulativeWeight, (userATokens * 10));
        assertEq(userData.lastUpdateTimestamp, 10);

        assertEq(userData.cumulativeWeight, cumulativeWeightCalc);
        
    }

    function testPoolTimeWeightCalculation() public {

        assert(pool.getPoolLastUpdateTimestamp() == 10);

        uint256 totalWeight = pool.getTotalCumulativeWeight();
        uint256 totalStaked = pool.getTotalStaked();

        // user weight == pool weight
        uint256 userWeight = userATokens * 10;

        assertEq(totalWeight, userWeight);
        assertEq(totalStaked, userATokens + userBTokens);

    }

}
