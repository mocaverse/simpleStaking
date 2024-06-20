// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {SimpleStaking} from "./../src/SimpleStaking.sol";

contract DeployMainnet is Script {

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // mocaToken on ethereum
        address mocaToken = 0xF944e35f95E819E752f3cCB5Faf40957d311e8c5;
        uint256 startTime = block.timestamp + (60 * 60);
        address owner = 0x1291d48f9524cE496bE32D2DC33D5E157b6Ed1e3;
        address updater = 0xdE05a1Abb121113a33eeD248BD91ddC254d5E9Db;

        SimpleStaking simpleStaking = new SimpleStaking(mocaToken, startTime, owner, updater);

        vm.stopBroadcast();
    }
}

// forge script script/Deploy.s.sol:DeployMainnet --rpc-url mainnet --broadcast --verify -vvvv --etherscan-api-key mainnet