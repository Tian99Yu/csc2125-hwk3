// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ITicketNFT} from "./interfaces/ITicketNFT.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract TicketNFT is ERC1155, ITicketNFT {
    // your code goes here (you can do it!)
    address ownerAddress;
    constructor(address addressIn) ERC1155("https://csc2125hwk3/ticket/{id}.json") {
        ownerAddress = addressIn;
    }

    function mintFromMarketPlace(address to, uint256 nftId) external override {
        _mint(to, nftId, 1, "");
    }

    function owner() public view returns (address) {
        return ownerAddress;
    }
}