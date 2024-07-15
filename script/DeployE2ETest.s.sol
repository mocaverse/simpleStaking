// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {SimpleStaking} from "./../src/SimpleStaking.sol";

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";


contract DeployMainnetTest is Script {

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // mocaToken on ethereum
        address testToken = 0xce748762f5b24F8060b5bfa87ee2fe0BD92B35B9;
        uint256 startTime = block.timestamp + (60 * 60);
        address owner = 0x8C9C001F821c04513616fd7962B2D8c62f925fD2;
        address updater = 0x4412CF7E4C15c1e901DAE68EBaAB3A7BdC32bb8E;   //TF

        SimpleStaking simpleStaking = new SimpleStaking(testToken, startTime, owner, updater);

        vm.stopBroadcast();
    }
}

// forge script script/DeployE2ETest.s.sol:DeployMainnetTest --rpc-url mainnet --broadcast --verify -vvvv --etherscan-api-key mainnet --legacy


contract GiveTokens is Script {


    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // send to updater
        address updater = 0x4412CF7E4C15c1e901DAE68EBaAB3A7BdC32bb8E;
        address testToken = 0xce748762f5b24F8060b5bfa87ee2fe0BD92B35B9;

        ERC20(testToken).transfer(updater, 6000 ether);

        vm.stopBroadcast();
    }
}

// forge script script/DeployE2ETest.s.sol:GiveTokens --rpc-url mainnet --broadcast -vvvv --etherscan-api-key mainnet --legacy


contract IssueGas is Script {

    function run() public {

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address[] memory addr = new address[](6);

            addr[0] = 0xb6AD69e681BB39A3A899fA88d1F102dB249a1162;
            addr[1] = 0x80848D587651546B7de1e9BAF4b27fE9C8eFfda5;
            addr[2] = 0x0FF3Ae150F1534a8673167c55e7A2A651C7F73e4;    
            addr[3] = 0xd08ccAA6F4ee4E250fC258bD1e2a69d475d9Bad4;
            addr[4] = 0x8c0F3e9E0d4b1d41f2B6f1021357aca77FAe406C;
            addr[5] = 0x8F93daA325708c6e7a83e3b4e9AA641f1B73661C;

        uint256 amount = 0.01 ether;

        for (uint256 i = 0; i < 6; i++) {

            bool sent = payable(addr[i]).send(amount);
            require(sent, "Failed to send Ether");
        }
        

        vm.stopBroadcast();
    }
}

// forge script script/DeployE2ETest.s.sol:IssueGas --rpc-url mainnet --broadcast -vvvv --etherscan-api-key mainnet --legacy

contract IssueGasLive is Script {

    function run() public {

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // send to SimpleStakingUpdater
        address ssUpdater = 0x0aDB8F65C59cedDD90c210a0CaEd33B18906CD48;
            bool sent_1 = payable(ssUpdater).send(0.355 ether);
            require(sent_1, "Failed to send Ether");       

        vm.stopBroadcast();
    }
}

// forge script script/DeployE2ETest.s.sol:IssueGasLive --rpc-url mainnet --broadcast -vvvv --etherscan-api-key mainnet --legacy