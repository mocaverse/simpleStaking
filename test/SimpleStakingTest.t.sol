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

    function setUp() public {
    
        // users
        userA = makeAddr("userA");
        userB = makeAddr("userB");
        userC = makeAddr("userC");
        owner = makeAddr("owner");

        // values
        userATokens = 30 ether;
        userBTokens = 50 ether;
        userCTokens = 80 ether;

        //contracts
        mocaToken = new ERC20Mock();    
        pool = new SimpleStaking(address(mocaToken));

        // mint 
        mocaToken.mint(userA, userATokens);
        mocaToken.mint(userB, userBTokens);
        mocaToken.mint(userC, userCTokens);

    }




}


contract StateZero is StateZeroTest {



}
