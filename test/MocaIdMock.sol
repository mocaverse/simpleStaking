// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract MocaIdMock is ERC721 {

    constructor() ERC721("mocaID", "mocaID"){}

    function mint(address to, uint256 tokenId) external {
        _safeMint(to, tokenId);
    }

}
