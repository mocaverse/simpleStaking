// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {SimpleStaking} from "./../src/SimpleStaking.sol";

contract DeployMainnet is Script {

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_ACTUAL");
        vm.startBroadcast(deployerPrivateKey);

        // mocaToken on ethereum
        address mocaToken = 0xF944e35f95E819E752f3cCB5Faf40957d311e8c5;
        uint256 startTime = 1720688400;
        address owner = 0x84Db3d1de9a43Aa144C21b248AD31a1c83d8334D;
        address updater = 0x84Db3d1de9a43Aa144C21b248AD31a1c83d8334D;

        SimpleStaking simpleStaking = new SimpleStaking(mocaToken, startTime, owner, updater);

        vm.stopBroadcast();
    }
}

// forge script script/Deploy.s.sol:DeployMainnet --rpc-url mainnet --broadcast --verify -vvvv --etherscan-api-key mainnet


contract ChangeUpdater is Script {

        function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_ACTUAL");
        vm.startBroadcast(deployerPrivateKey);

        // dat multisig
        address newUpdater = 0x0aDB8F65C59cedDD90c210a0CaEd33B18906CD48;
        address simpleStaking = 0x9a98E6B60784634AE273F2FB84519C7F1885AeD2;
        
        SimpleStaking(simpleStaking).changeUpdater(newUpdater);

        vm.stopBroadcast();
    }

}

// forge script script/Deploy.s.sol:ChangeUpdater --rpc-url mainnet --broadcast --verify -vvvv --etherscan-api-key mainnet --legacy

contract TransferOwnership is Script {

        function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY_ACTUAL");
        vm.startBroadcast(deployerPrivateKey);

        // dat multisig
        address newOwner = 0xed699aB8547440729de9b8D104e93d5b013D7973;
        address simpleStaking = 0x9a98E6B60784634AE273F2FB84519C7F1885AeD2;
        
        SimpleStaking(simpleStaking).transferOwnership(newOwner);

        vm.stopBroadcast();
    }

}

// forge script script/Deploy.s.sol:TransferOwnership --rpc-url mainnet --broadcast --verify -vvvv --etherscan-api-key mainnet --legacy
