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

    uint256 public userATokens;
    uint256 public userBTokens;
    uint256 public userCTokens;
    uint256 public ownerTokens;

    uint256 public startTime = 1;

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

        // values
        userATokens = 20 ether;
        userBTokens = 50 ether;
        userCTokens = 80 ether;
        ownerTokens = 50 ether;

        //contracts
        mocaToken = new ERC20Mock();    
        pool = new SimpleStaking(address(mocaToken), startTime, owner);

        // mint tokens
        mocaToken.mint(userA, userATokens);
        mocaToken.mint(userB, userBTokens);
        mocaToken.mint(userC, userCTokens);
        mocaToken.mint(owner, ownerTokens);

        // allowance
        vm.prank(userA);
        mocaToken.approve(address(pool), userATokens);

        vm.prank(userB);
        mocaToken.approve(address(pool), userBTokens);
        
        vm.prank(userC);
        mocaToken.approve(address(pool), userCTokens);

        vm.prank(owner);
        mocaToken.approve(address(pool), ownerTokens);

        // set time
        vm.warp(0);

        // userA stake
        vm.expectEmit(true, true, false, false);
        emit Staked(userA, userATokens);

        vm.prank(userA);
        pool.stake(userATokens);

    }
}


//note: Staking not started. Users can stake/unstake, but no cumWeight
contract StateZeroTest is StateZero {

    function testTokenGetter() public {
        address tokenAddress = pool.getMocaToken();
        assertEq(tokenAddress, address(mocaToken));
    }

    function testStartTime() public {
        pool.getStartTime();
        assertEq(pool.getStartTime(), 1);
    }

    function testCannotStakeZero() public {
        
        vm.prank(userA);
        vm.expectRevert("Zero amount");
        pool.stake(0);
    }

    function testCannotUnstakeBeforeStartTime() public {
        
        vm.prank(userA);
        vm.expectRevert("Not started");
        pool.unstake(0);
    }


    function testUserAStake() public {

        // tokens
        assertEq(mocaToken.balanceOf(userA), 0);
        assertEq(mocaToken.balanceOf(address(pool)), userATokens);

        // get user data
        SimpleStaking.Data memory userData = pool.getUser(userA);
        
        // user data
        assertEq(userData.amount, userATokens);
        assertEq(userData.cumulativeWeight, 0);
        assertEq(userData.lastUpdateTimestamp, 0);

        // pool data
        assertEq(pool.getPoolLastUpdateTimestamp(), userData.lastUpdateTimestamp);
        assertEq(pool.getTotalStaked(), userData.amount);
    }

    function testUpdatePoolOnStakeTwice() public {
        //  ensure that  _poolLastUpdateTimestamp remains as startTime,
        //  if stake has been more than once

        vm.startPrank(userB);
            pool.stake(userBTokens/2);
            pool.stake(userBTokens/2);
        vm.stopPrank();

        // tokens
        assertEq(mocaToken.balanceOf(userB), 0);
        assertEq(mocaToken.balanceOf(address(pool)), (userBTokens + userATokens));

        // get user data
        SimpleStaking.Data memory userData = pool.getUser(userB);
        
        // user data
        assertEq(userData.amount, userBTokens);
        assertEq(userData.cumulativeWeight, 0);
        assertEq(userData.lastUpdateTimestamp, 0);

        // pool data
        assertEq(pool.getPoolLastUpdateTimestamp(), userData.lastUpdateTimestamp);
        assertEq(pool.getTotalStaked(), (userData.amount + userATokens));        
    }

    function testGetTotalStakedDoesNotChangeOnDirectTransfer() public {
        vm.prank(userB);
        mocaToken.transfer(address(pool), userBTokens);

        assertEq(pool.getTotalStaked(), userATokens);
    }

    function testStakeBehalfArrayIncorrectLength() public {
        address[] memory users = new address[](5);
            users[0] = address(1);
            users[1] = address(2);
            users[2] = address(3);
            users[3] = address(4);
            users[4] = address(5);
        
        uint256[] memory amounts = new uint256[](3);
            amounts[0] = 10 ether;
            amounts[1] = 10 ether;
            amounts[2] = 10 ether;
            

        vm.prank(owner);
        vm.expectRevert("Incorrect lengths");
        pool.stakeBehalf(users, amounts);
    }

    function testStakeBehalfEmptyArray() public {
        address[] memory users = new address[](0);        
        uint256[] memory amounts = new uint256[](0);

        vm.prank(owner);
        vm.expectRevert("Empty array");
        pool.stakeBehalf(users, amounts);
    }

    function testStakeBehalfArrayMaxLength() public {
        address[] memory users = new address[](11);
            users[0] = address(1);
            users[1] = address(2);
            users[2] = address(3);
            users[3] = address(4);
            users[4] = address(5);

        uint256[] memory amounts = new uint256[](11);
            amounts[0] = 10 ether;
            amounts[1] = 10 ether;
            amounts[2] = 10 ether;
            amounts[3] = 10 ether;
            amounts[4] = 10 ether;
      
        
        vm.prank(owner);
        vm.expectRevert("Array max length exceeded");
        pool.stakeBehalf(users, amounts);
    }


    function testOwnerCanStakeBehalf() public {

        address[] memory users = new address[](5);
            users[0] = address(1);
            users[1] = address(2);
            users[2] = address(3);
            users[3] = address(4);
            users[4] = address(5);
        
        uint256[] memory amounts = new uint256[](5);
            amounts[0] = 10 ether;
            amounts[1] = 10 ether;
            amounts[2] = 10 ether;
            amounts[3] = 10 ether;
            amounts[4] = 10 ether;

        // check events
        vm.expectEmit(true, true, true, false);
        emit StakedBehalf(users, amounts);

        vm.prank(owner);
        pool.stakeBehalf(users, amounts);

        // assert: token transfers
        assertEq(mocaToken.balanceOf(owner), 0);
        assertEq(mocaToken.balanceOf(address(pool)), (ownerTokens + userATokens));

        // assert: Pool data
        assertEq(pool.getTotalStaked(), (ownerTokens + userATokens));
        assertEq(pool.getPoolCumulativeWeight(), 0);

        // assert: users
        SimpleStaking.Data memory user1 = pool.getUser(address(1));
        SimpleStaking.Data memory user2 = pool.getUser(address(2));
        SimpleStaking.Data memory user3 = pool.getUser(address(3));
        SimpleStaking.Data memory user4 = pool.getUser(address(4));
        SimpleStaking.Data memory user5 = pool.getUser(address(5));

        assertEq(user1.amount, 10 ether);
        assertEq(user2.amount, 10 ether);
        assertEq(user3.amount, 10 ether);
        assertEq(user4.amount, 10 ether);
        assertEq(user5.amount, 10 ether);

    }

}


// note: time = 01. userA stakes
abstract contract StateT01 is StateZero {

    function setUp() public virtual override {
        super.setUp();

        vm.warp(1);
        
    }
}

contract StateT01Test is StateT01 {

    function testUserCanStakeOnStart() public {
        
        // tokens
        assertEq(mocaToken.balanceOf(userA), 0);
        assertEq(mocaToken.balanceOf(address(pool)), userATokens);

        // get user data
        SimpleStaking.Data memory userData = pool.getUser(userA);
        
        // user data
        assertEq(userData.amount, userATokens);
        assertEq(userData.cumulativeWeight, 0);
        assertEq(userData.lastUpdateTimestamp, 0);  //timestamps are only updated AFTER staking has begun

        // pool data  
        assertEq(pool.getPoolLastUpdateTimestamp(), 0);  //timestamps are only updated AFTER staking has begun
        assertEq(pool.getTotalStaked(), userData.amount);
    }

    function testGetPoolTimeCalculation() public {
        // getPoolCumulativeWeight should return the same value as _totalCumulativeWeight if _poolLastUpdateTimestamp and block.timestamp are the same.
        // unbookedWeight should be 0
        assertEq(pool.getPoolCumulativeWeight(), pool.getTotalCumulativeWeight());
    }
    
    function testGetUserCumulativeWeight() public {
        // getUserCumulativeWeight(A) should give the same value as getUser(A).cumulativeWeight 
        // if userData.lastUpdateTimestamp and block.timestamp are the same.

        // get user data
        SimpleStaking.Data memory userData = pool.getUser(userA);

        assertEq(pool.getUserCumulativeWeight(userA), userData.cumulativeWeight);
    }

    function testCannotUnstakeZero() public {
        
        vm.prank(userA);
        vm.expectRevert("Zero amount");
        pool.unstake(0);
    }

    function testCannotUnstakeExcess() public {
        
        vm.prank(userA);
        vm.expectRevert("Insufficient balance");
        pool.unstake(userATokens * 2);
    }	

    function testUserCanUnstakeOnStart() public {

        vm.prank(userA);
        pool.unstake(userATokens);
        
        // tokens
        assertEq(mocaToken.balanceOf(userA), userATokens);
        assertEq(mocaToken.balanceOf(address(pool)), 0);

        // get user data
        SimpleStaking.Data memory userData = pool.getUser(userA);
        
        // user data 
        assertEq(userData.amount, 0);
        assertEq(userData.cumulativeWeight, 0);
        assertEq(userData.lastUpdateTimestamp, 0);

        // pool data
        assertEq(pool.getPoolLastUpdateTimestamp(), 0); 
        assertEq(pool.getTotalStaked(), 0);
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

    function testUserACanUnstake() public {
        
        vm.prank(userA);
        pool.unstake(userATokens);
        
        // tokens
        assertEq(mocaToken.balanceOf(userA), userATokens);
        assertEq(mocaToken.balanceOf(address(pool)), 0);

        // get user data
        SimpleStaking.Data memory userData = pool.getUser(userA);
        
        // weight should be: timeDelta * amount = (10 - 1) * userATokens
        assertEq(userData.amount, 0);
        assertEq(userData.cumulativeWeight, ((10 - 1) * userATokens));
        assertEq(userData.lastUpdateTimestamp, 10);
    }

    function testUserATimeWeightCalculation() public {

        uint256 cumulativeWeightGetter = pool.getUserCumulativeWeight(userA);

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
        uint256 totalPoolWeight = pool.getPoolCumulativeWeight();
        uint256 cumulativeWeight = pool.getTotalCumulativeWeight();
        
        // staked at t=1
        uint256 userWeight = userATokens * (10 - 1);
        
        // user weight == pool weight
        assertEq(totalPoolWeight, userWeight);
        assertEq(totalStaked, userATokens);
        assertEq(cumulativeWeight, 0);  // 0 since no txn since stake
    }
}

abstract contract StateT11 is StateT10 {

    function setUp() public virtual override {
        super.setUp();

        vm.warp(11);

        vm.prank(userB);
        pool.stake(userBTokens/2);
    }
}

contract StateT11Test is StateT11 {

    function testPoolTimeWeightCalculationT11() public {

        // pool updated
        assert(pool.getPoolLastUpdateTimestamp() == 11);

        uint256 totalStaked = pool.getTotalStaked();
        uint256 totalPoolWeight = pool.getPoolCumulativeWeight();
        uint256 cumulativeWeight = pool.getTotalCumulativeWeight();

        // user weight == pool weight
        uint256 userWeight = userATokens * (11 - 1);

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

        uint256 cumulativeWeightGetter = pool.getUserCumulativeWeight(userB);

        assertEq(cumulativeWeightGetter, 0);
    }

}

abstract contract StateT12 is StateT11 {    
    
    function setUp() public virtual override {
        super.setUp();

        vm.warp(12);

        vm.prank(userB);
        pool.stake(userBTokens/2);
    }
}

contract StateT12Test is StateT12 {

    function testUserAndPoolStateT12() public {

        // get user data
        SimpleStaking.Data memory userData = pool.getUser(userB);

        assertEq(userData.amount, userBTokens);
        assertEq(userData.cumulativeWeight, (userBTokens/2 * 1));
        assertEq(userData.lastUpdateTimestamp, 12);

        // get pool data
        uint256 userBWeight = pool.getUserCumulativeWeight(userB);
    
        uint256 totalStaked = pool.getTotalStaked();
        uint256 poolLastUpdateTimestamp = pool.getPoolLastUpdateTimestamp();

        /**
            totalCumulativeWeight

            t1: userA -> stakes 20 ether;
            t11: userB -> stakes 25 ether;
            t12: userB -> stakes 25 ether;
         */

        // calc weight increment
        uint256 totalCumulativeWeight = pool.getTotalCumulativeWeight();
        uint256 cumulativeWeightCalc = ((12 - 1) * userATokens) + ((12 - 11) * userBTokens/2); 

        assertEq(userBWeight, (userBTokens/2 * (12 - 11)));
        assertEq(totalStaked, userATokens + userBTokens);
        assertEq(poolLastUpdateTimestamp, 12);

        assertEq(totalCumulativeWeight, cumulativeWeightCalc);
    }
}

abstract contract StatePaused is StateT12 {
    
    function setUp() public virtual override {
        super.setUp();
        
        vm.prank(owner);
        pool.pause();
    }    
}

contract StatePausedTest is StatePaused {

    function testPausedPool() public {
        // unstake
        vm.prank(userA);
        pool.unstake(userATokens);
        
        // stake
        vm.prank(userC);
        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));
        pool.stake(userCTokens);

        //owner
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(Pausable.EnforcedPause.selector));

        address[] memory users = new address[](2);
            users[0] = address(1);
            users[1] = address(2);

        uint256[] memory amounts = new uint256[](2);
            amounts[0] = 10 ether;
            amounts[1] = 10 ether;
            
        pool.stakeBehalf(users, amounts);
    }
}

abstract contract StateUnpaused is StatePaused {
    
    function setUp() public virtual override {
        super.setUp();
        
        vm.prank(owner);
        pool.unpause();
    }     
}

contract StateUnpausedTest is StateUnpaused {

    function testUnpausedPool() public {
        // unstake
        vm.prank(userA);
        pool.unstake(userATokens);
        
        // stake
        vm.prank(userC);
        pool.stake(userCTokens);

        //owner
        vm.prank(owner);

        address[] memory users = new address[](2);
            users[0] = address(1);
            users[1] = address(2);

        uint256[] memory amounts = new uint256[](2);
            amounts[0] = 10 ether;
            amounts[1] = 10 ether;
            
        pool.stakeBehalf(users, amounts);
    }
}