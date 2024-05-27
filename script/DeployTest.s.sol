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

// forge script script/DeployTest.s.sol:MintStake --rpc-url sepolia --broadcast -vvvv