// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ITicketNFT} from "./interfaces/ITicketNFT.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract TicketNFT is ERC1155, ITicketNFT {
    // your code goes here (you can do it!)
    address owner_nft;
    constructor(address owner_ad) ERC1155("https://api.example.com/ticket/{id}.json") {
        owner_nft = owner_ad;
    }

    function mintFromMarketPlace(address to, uint256 nftId) external override {
        _mint(to, nftId, 1, "");
    }
    function owner() external view returns (address) {
        return owner_nft;
    }
}