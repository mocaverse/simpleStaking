// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {SimpleStaking} from "./../src/SimpleStaking.sol";

contract DeployMainnet is Script {

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // mocaToken on ethereum
        address mocaToken = 0x5667424802Ef74C314e7adbBa6fA669999d8137D;
        uint256 startTime = block.timestamp + (60 * 60);
        address owner = 0xdE05a1Abb121113a33eeD248BD91ddC254d5E9Db;
        address updater = 0x8F93daA325708c6e7a83e3b4e9AA641f1B73661C;

        SimpleStaking simpleStaking = new SimpleStaking(mocaToken, startTime, owner, updater);

        vm.stopBroadcast();
    }
}

// forge script script/Deploy.s.sol:DeployMainnet --rpc-url mainnet --broadcast --verify -vvvv --etherscan-api-key mainnet