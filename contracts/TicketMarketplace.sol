// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ITicketNFT} from "./interfaces/ITicketNFT.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TicketNFT} from "./TicketNFT.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol"; 
import {ITicketMarketplace} from "./interfaces/ITicketMarketplace.sol";
import "hardhat/console.sol";

contract TicketMarketplace is ITicketMarketplace {
    address scAddress;
    TicketNFT ticketNFT;
    uint128 curID=0;
    string ETH_TYPE = "ETH";
    string ERC20_TYPE = "ERC20";

    struct Event{
        uint128 eventId;
        uint128 maxTickets;
        uint256 pricePerTicket;
        uint256 pricePerTicketERC20;
        uint128 curTicketNumber;
    }

    mapping(uint128 => Event) public events;

    constructor(address addressIn) {
        scAddress = addressIn;
        ticketNFT = new TicketNFT();
    }

    function checkPermission() internal view {
        require(msg.sender == scAddress, "No permission to perform this action");
    }

    function createEvent(uint128 maxTickets, uint256 pricePerTicket, uint256 pricePerTicketERC20) external override {
        checkPermission();
        events[curID] = Event(curID, maxTickets, pricePerTicket, pricePerTicketERC20, 0);
        curID++;
        emit EventCreated(curID, maxTickets, pricePerTicket, pricePerTicketERC20);
    }

    function setMaxTicketsForEvent(uint128 eventId, uint128 newMaxTickets) external override{
        checkPermission();
        events[eventId].maxTickets = newMaxTickets;
        emit MaxTicketsUpdate(eventId, newMaxTickets);
    }

    function setPriceForTicketETH(uint128 eventId, uint256 price) external override{
        checkPermission();
        events[eventId].pricePerTicket = price;
        emit PriceUpdate(eventId, price, ETH_TYPE);
    }

    function setPriceForTicketERC20(uint128 eventId, uint256 price) external override{
        checkPermission();
        events[eventId].pricePerTicketERC20 = price;
        emit PriceUpdate(eventId, price, ERC20_TYPE);
    }

    function buyTickets(uint128 eventId, uint128 ticketCount) payable external override{
        console.log(events[10].eventId);

        require(events[eventId].maxTickets > ticketCount + events[eventId].curTicketNumber, "Not enough tickets available");
        require(events[eventId].pricePerTicket * ticketCount == msg.value, "Incorrect amount of ETH sent");
        ticketNFT.mintFromMarketPlace(msg.sender, eventId);
        emit TicketsBought(eventId, ticketCount, ETH_TYPE);
        events[eventId].curTicketNumber += ticketCount;
    }

    function buyTicketsERC20(uint128 eventId, uint128 ticketCount) external override{
        require(events[eventId].maxTickets > ticketCount + events[eventId].curTicketNumber, "Not enough tickets available");

    }

    function setERC20Address(address newERC20Address) external override{
        checkPermission();
        scAddress = newERC20Address;
        emit ERC20AddressUpdate(newERC20Address);
    }


}