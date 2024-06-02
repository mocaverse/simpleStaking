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
        emit Staked(userA, userATokens);

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

// note: time = 01. user A stakes to self
abstract contract StateT01 is StateZero {

    function setUp() public virtual override {
        super.setUp();

        vm.warp(1);

        vm.prank(userA);
        pool.stake(userA, userATokens);
    }
}

contract StateT01Test is StateT01 {

    function testUserCanUnstake() public {
        
        vm.prank(userA);
        pool.unstake(userATokens);

        assertEq(mocaToken.balanceOf(userA), userATokens);
        assertEq(mocaToken.balanceOf(address(pool)), 0);

        // get user data
        SimpleStaking.Data memory userData = pool.getUser(userA);
        
        // just staked. weight should be 0
        assertEq(userData.amount, 0);
        assertEq(userData.cumulativeWeight, 0);
        assertEq(userData.lastUpdateTimestamp, 1);
    }

    function testGetPoolTimeCalculation() public {
        // getPoolTimeWeight should return the same value as _totalCumulativeWeight if _poolLastUpdateTimestamp and block.timestamp are the same.
        // unbookedWeight should be o

        assertEq(pool.getPoolCumulativeWeight(), pool.getTotalCumulativeWeight());
    }
    
    function testGetUserCumulativeWeight() public {
        // getUserCumulativeWeight(A) should give the same value as getUser(A).cumulativeWeight 
        // if userData.lastUpdateTimestamp and block.timestamp are the same.

        // get user data
        SimpleStaking.Data memory userData = pool.getUser(userA);

        assertEq(pool.getUserCumulativeWeight(userA), userData.cumulativeWeight);
    }

}

//note: 
abstract contract StateT10 is StateT01 {

    function setUp() public virtual override {
        super.setUp();

        vm.warp(10);
    }
}


contract StateT10Test is StateT10 {
    
    function testUserATimeWeightCalculation() public {

        uint256 cumulativeWeightGetter = pool.getAddressTimeWeight(userA);

        //calc.
        uint256 timeDelta = 10 - 1;
        uint256 cumulativeWeightCalc = timeDelta * userATokens;

        assertEq(cumulativeWeightGetter, cumulativeWeightCalc);

        // exec. state transition
        vm.prank(userA);
        pool.unstake(userATokens);

        // get user data
        SimpleStaking.Data memory userData = pool.getUser(userA);
        
        assertEq(userData.amount, 0);
        assertEq(userData.cumulativeWeight, (userATokens * 9));
        assertEq(userData.lastUpdateTimestamp, 10);

        assertEq(userData.cumulativeWeight, cumulativeWeightCalc);
        
    }

    function testPoolTimeWeightCalculation() public {
        // pool not updated
        assert(pool.getPoolLastUpdateTimestamp() == 0);

        uint256 totalStaked = pool.getTotalStaked();
        uint256 totalPoolWeight = pool.getPoolTimeWeight();
        uint256 cumulativeWeight = pool.getTotalCumulativeWeight();

        // user weight == pool weight
        uint256 userWeight = userATokens * 10;

        assertEq(totalPoolWeight, userWeight);
        assertEq(totalStaked, userATokens);
        assertEq(cumulativeWeight, 0);
    }
}

abstract contract StateT11 is StateT10 {

    function setUp() public virtual override {
        super.setUp();

        vm.warp(11);

        vm.prank(userB);
        pool.stake(userB, userBTokens/2);
    }
}

contract StateT11Test is StateT11 {

    function testPoolTimeWeightCalculation() public {

        // pool updated
        assert(pool.getPoolLastUpdateTimestamp() == 11);

        uint256 totalStaked = pool.getTotalStaked();
        uint256 totalPoolWeight = pool.getPoolTimeWeight();
        uint256 cumulativeWeight = pool.getTotalCumulativeWeight();

        // user weight == pool weight
        uint256 userWeight = userATokens * 11;

        assertEq(totalPoolWeight, userWeight);
        assertEq(totalStaked, userATokens +  userBTokens/2);
        assertEq(cumulativeWeight, userWeight);
    }

    function testUserBTimeWeightT11() public {

        // get user data
        SimpleStaking.Data memory userData = pool.getUser(userB);

        assertEq(userData.amount, userBTokens/2);
        assertEq(userData.cumulativeWeight, 0);
        assertEq(userData.lastUpdateTimestamp, 11);

        uint256 cumulativeWeightGetter = pool.getAddressTimeWeight(userB);

        assertEq(cumulativeWeightGetter, 0);
    }

}

abstract contract StateT12 is StateT11 {
    
    function setUp() public virtual override {
        super.setUp();

        vm.warp(12);

        vm.prank(userB);
        pool.stake(userB, userBTokens/2);
    }
}

contract StateT12Test is StateT12 {

    function testUserAndPoolState() public {

        // get user data
        SimpleStaking.Data memory userData = pool.getUser(userB);

        assertEq(userData.amount, userBTokens);
        assertEq(userData.cumulativeWeight, (userBTokens/2 * 1));
        assertEq(userData.lastUpdateTimestamp, 12);

        // get pool data
        uint256 cumulativeWeightGetter = pool.getUserCumulativeWeight(userB);
    
        uint256 totalStaked = pool.getTotalStaked();
        uint256 poolLastUpdateTimestamp = pool.getPoolLastUpdateTimestamp();

        // calc weight increment
        uint256 totalCumulativeWeight = pool.getTotalCumulativeWeight();
        uint256 cumulativeWeightCalc = (timeDelta * userATokens) + (); 

        assertEq(cumulativeWeightGetter, (userBTokens/2 * 1));
        assertEq(totalStaked, userATokens + userBTokens);
        assertEq(poolLastUpdateTimestamp, 12);
        assertEq(totalCumulativeWeight, );
    }

}

/**
When a user stakes a non-zero amount and has a non-zero staking balance before:
userData.cumulativeWeight should be incremented by pre-update balance * (now - pre-update userData.lastUpdateTimestamp)
_totalCumulativeWeight should  be incremented by  pre-update _totalStaked * (now - pre-update _poolLastUpdateTimestamp)


 */