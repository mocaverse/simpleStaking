// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface IREALMID {

    function ownerOf(uint256 tokenId) external view returns (address);
}