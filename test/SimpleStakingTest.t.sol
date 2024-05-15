// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SimpleStaking} from "../src/SimpleStaking.sol";

import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import "test/MocaIdMock.sol";

abstract contract StateZero is Test {

    SimpleStaking public pool;
    ERC20Mock public mocaToken;
    MocaIdMock public mocaId;

    address public userA;
    address public userB;
    address public userC;
    address public owner;

    uint256 public userATokens;
    uint256 public userBTokens;
    uint256 public userCTokens;

    // events 
    event Staked(address indexed user, uint256 indexed id, uint256 amount);
    event Unstaked(address indexed user, uint256 indexed id, uint256 amount);

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
        mocaId = new MocaIdMock();
        pool = new SimpleStaking(address(mocaToken), address(mocaId));

        // mint tokens
        mocaToken.mint(userA, userATokens);
        mocaToken.mint(userB, userBTokens);
        mocaToken.mint(userC, userCTokens);

        // mint Ids
        mocaId.mint(userA, 0);
        mocaId.mint(userB, 1);
        mocaId.mint(userC, 2);
        
    }

}


contract StateZeroTest is StateZero {


    function testUserCannotStakeToUnmintedId() public {
        
        vm.prank(userA);
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, 11));
        pool.stake(11, userATokens);

    }

    function testUserCanStakeToMintedId() public {
        // allowance
        vm.prank(userA);
        mocaToken.approve(address(pool), userATokens);

        // check events
        vm.expectEmit(true, true, false, false);
        emit Staked(userA, 0, userATokens);

        vm.prank(userA);
        pool.stake(0, userATokens);

        assertEq(mocaToken.balanceOf(userA), 0);
        assertEq(mocaToken.balanceOf(address(pool)), userATokens);

        (uint256 amount, uint256 timeWeighted, uint256 lastUpdateTimestamp) = pool.ids(0);
        
        assertEq(amount, userATokens);
        assertEq(timeWeighted, 0);
        assertEq(lastUpdateTimestamp, 0);
    }

    function testUserCanStakeToOtherMintedId() public {
        // allowance
        vm.prank(userA);
        mocaToken.approve(address(pool), userATokens);

        // check events
        vm.expectEmit(true, true, false, false);
        emit Staked(userA, 1, userATokens);

        vm.prank(userA);
        pool.stake(1, userATokens);

        assertEq(mocaToken.balanceOf(userA), 0);
        assertEq(mocaToken.balanceOf(address(pool)), userATokens);

        (uint256 amount, uint256 timeWeighted, uint256 lastUpdateTimestamp) = pool.ids(1);
        
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

        pool.stake(0, userATokens/2);
        pool.stake(1, userATokens/2);

        vm.stopPrank();
    }
}

contract StateStakedTest is StateStaked {

    function testUserCannotUnstakeAnother() public {
        
        // arbitrary user cannot unstake another's stake
        vm.prank(userB);
        vm.expectRevert("Insufficient user balance");
        pool.unstake(0, userATokens/2);
    }

    function testUserCanUnstake() public {
        
        vm.startPrank(userA);
            pool.unstake(0, userATokens/2);
            pool.unstake(1, userATokens/2);
        vm.stopPrank();

        assertEq(mocaToken.balanceOf(userA), userATokens);
        assertEq(mocaToken.balanceOf(address(pool)), 0);
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

        uint256 timeWeightGetter = pool.getIdTotalTimeWeight(0);

        //calc.
        uint256 timeDelta = 10 - 0;
        uint256 timeWeightCalc = timeDelta * userATokens/2;

        assertEq(timeWeightGetter, timeWeightCalc);

        // exec. state transition
        vm.prank(userA);
        pool.unstake(0, userATokens/2);

        uint256 timeWeightStoredUpdated = pool.getIdTotalTimeWeight(0);

        assertEq(timeWeightStoredUpdated, timeWeightCalc);
        
    }
}