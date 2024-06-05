// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {SimpleStaking} from "./../src/SimpleStaking.sol";

contract DeployTestSepolia is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // mocaToken = 0x5667424802Ef74C314e7adbBa6fA669999d8137D
        SimpleStaking simpleStaking = new SimpleStaking(0x5667424802Ef74C314e7adbBa6fA669999d8137D);

        vm.stopBroadcast();
        
    }
}

// forge script script/DeployTest.s.sol:DeployTestSepolia --rpc-url sepolia --broadcast --verify -vvvv --etherscan-api-key sepolia

interface IMoca {

    function mint(uint256) external;
    function approve(address, uint256) external;
}

/*
contract MintStake is Script {

    function run() public {

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        IMoca(0x5667424802Ef74C314e7adbBa6fA669999d8137D).mint(10 ether);
        IMoca(0x5667424802Ef74C314e7adbBa6fA669999d8137D).approve(0x2EF1b6BcFf31b64ee4Fd5A3CF9e7b58a2eaea8D5, 10 ether);
        
        SimpleStaking(0x2EF1b6BcFf31b64ee4Fd5A3CF9e7b58a2eaea8D5).stake(10 ether);

        vm.stopBroadcast();
    }
}
*/

// forge script script/DeployTest.s.sol:MintStake --rpc-url sepolia --broadcast -vvvv

contract StakeBehalf is Script {

    function run() public {

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        IMoca(0x5667424802Ef74C314e7adbBa6fA669999d8137D).mint(10 ether);
        IMoca(0x5667424802Ef74C314e7adbBa6fA669999d8137D).approve(0x2EF1b6BcFf31b64ee4Fd5A3CF9e7b58a2eaea8D5, 10 ether);

        address[] memory users = new address[](5);
            users[0] = 0xdE05a1Abb121113a33eeD248BD91ddC254d5E9Db;
            users[1] = 0xdE05a1Abb121113a33eeD248BD91ddC254d5E9Db;
            users[2] = 0xdE05a1Abb121113a33eeD248BD91ddC254d5E9Db;
            users[3] = 0xdE05a1Abb121113a33eeD248BD91ddC254d5E9Db;
            users[4] = 0xdE05a1Abb121113a33eeD248BD91ddC254d5E9Db;

        uint256[] memory amounts = new uint256[](5);
            amounts[0] = 5 ether;
            amounts[1] = 5 ether;
            amounts[2] = 5 ether;
            amounts[3] = 5 ether;
            amounts[4] = 5 ether;


        SimpleStaking(0xa970B29C8634A4D50f0ae1C29724a09399ceF2D9).stakeBehalf(users, amounts);

        vm.stopBroadcast();
    }
}

// forge script script/DeployTest.s.sol:StakeBehalf --rpc-url sepolia --broadcast -vvvv
