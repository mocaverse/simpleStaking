// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {SimpleStaking} from "./../src/SimpleStaking.sol";

contract DeployTestSepolia is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // mocaToken = 0xF944e35f95E819E752f3cCB5Faf40957d311e8c5 [ethereum]
        uint256 startTime = block.timestamp + (60 * 60);
        SimpleStaking simpleStaking = new SimpleStaking(0x5667424802Ef74C314e7adbBa6fA669999d8137D, startTime, 0xdE05a1Abb121113a33eeD248BD91ddC254d5E9Db, 0x8F93daA325708c6e7a83e3b4e9AA641f1B73661C);

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

        //IMoca(0x5667424802Ef74C314e7adbBa6fA669999d8137D).mint(100 ether);
        //IMoca(0x5667424802Ef74C314e7adbBa6fA669999d8137D).approve(0x55105f426126952AC6d9C2E7e72C7451318617D3, 100 ether);

        address[] memory users = new address[](3);
            users[0] = 0xdE05a1Abb121113a33eeD248BD91ddC254d5E9Db;
            users[1] = 0xdE05a1Abb121113a33eeD248BD91ddC254d5E9Db;
            users[2] = 0xdE05a1Abb121113a33eeD248BD91ddC254d5E9Db;
            //users[3] = 0xdE05a1Abb121113a33eeD248BD91ddC254d5E9Db;
            //users[4] = 0xdE05a1Abb121113a33eeD248BD91ddC254d5E9Db;

        uint256[] memory amounts = new uint256[](3);
            amounts[0] = 5 ether;
            amounts[1] = 5 ether;
            amounts[2] = 5 ether;
            //amounts[3] = 5 ether;
            //amounts[4] = 5 ether;


        SimpleStaking(0x55105f426126952AC6d9C2E7e72C7451318617D3).stakeBehalf(users, amounts);

        vm.stopBroadcast();
    }
}

// forge script script/DeployTest.s.sol:StakeBehalf --rpc-url sepolia --broadcast -vvvv

contract TransferOwnership is Script {
    function run() public {

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        SimpleStaking(0x40e556662859cAAE4Fb944b36020B94572165ab8).transferOwnership(0x8C9C001F821c04513616fd7962B2D8c62f925fD2);

        vm.stopBroadcast();
    }
}

// forge script script/DeployTest.s.sol:TransferOwnership --rpc-url sepolia --broadcast -vvvv
