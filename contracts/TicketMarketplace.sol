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
    address tmOwnerAddress;
    TicketNFT ticketNFT;
    uint128 curID=0;
    string ETH_TYPE = "ETH";
    string ERC20_TYPE = "ERC20";
    IERC20 erc20Coin;

    struct Event{
        uint128 eventId;
        uint128 maxTickets;
        uint256 pricePerTicket;
        uint256 pricePerTicketERC20;
        uint128 nextTicketToSell;
        bool exists;
    }

    mapping(uint128 => Event) public events;

    constructor(address addressIn) {
        scAddress = addressIn;
        // Deal with contract at scAddress as IERC20 type,
        // in our case, it is SampleCoin
        erc20Coin = IERC20(scAddress);
        ticketNFT = new TicketNFT(address(this));
        tmOwnerAddress = msg.sender;
    }

    function checkPermission(address senderAddress) internal view {
        require(senderAddress == tmOwnerAddress, "Unauthorized access");
    }

    function createEvent(uint128 maxTickets, uint256 pricePerTicket, uint256 pricePerTicketERC20) external override {
        checkPermission(msg.sender);
        events[curID] = Event(curID, maxTickets, pricePerTicket, pricePerTicketERC20, 0, true);
        emit EventCreated(curID, maxTickets, pricePerTicket, pricePerTicketERC20);
        curID++;
    }

    function setMaxTicketsForEvent(uint128 eventId, uint128 newMaxTickets) external override{
        checkPermission(msg.sender);
        require(newMaxTickets > events[eventId].maxTickets, "The new number of max tickets is too small!");
        events[eventId].maxTickets = newMaxTickets;
        emit MaxTicketsUpdate(eventId, newMaxTickets);
    }

    function setPriceForTicketETH(uint128 eventId, uint256 price) external override{
        checkPermission(msg.sender);
        events[eventId].pricePerTicket = price;
        emit PriceUpdate(eventId, price, ETH_TYPE);
    }

    function setPriceForTicketERC20(uint128 eventId, uint256 price) external override{
        checkPermission(msg.sender);
        events[eventId].pricePerTicketERC20 = price;
        emit PriceUpdate(eventId, price, ERC20_TYPE);
    }

    function getNftId(uint128 eventId, uint128 ticketCount) internal returns(uint256){
        return ((uint256)(eventId) << 128) + ticketCount;
    }

    function buyTickets(uint128 eventId, uint128 ticketCount) payable external override{
        Event storage curEvent = events[eventId];
        uint256 maxTicketCount = type(uint256).max / curEvent.pricePerTicket;
        require(curEvent.exists, "Event does not exist");
        require(ticketCount <= maxTicketCount, "Overflow happened while calculating the total price of tickets. Try buying smaller number of tickets.");
        require(curEvent.maxTickets > ticketCount + curEvent.nextTicketToSell, "We don't have that many tickets left to sell!");
        require(curEvent.pricePerTicket * ticketCount <= msg.value, "Not enough funds supplied to buy the specified number of tickets.");
        // Buy ticket one by one
        for (uint128 i = 0; i < ticketCount; i++){
            ticketNFT.mintFromMarketPlace(msg.sender, getNftId(eventId, curEvent.nextTicketToSell + i));
        }
        // update the Event
        curEvent.nextTicketToSell += ticketCount;
        emit TicketsBought(eventId, ticketCount, ETH_TYPE);
    }

    function buyTicketsERC20(uint128 eventId, uint128 ticketCount) external override{
        Event storage curEvent = events[eventId];
        uint256 maxTicketCount = type(uint256).max / curEvent.pricePerTicketERC20;

        require(curEvent.exists, "Event does not exist");
        require(ticketCount <= maxTicketCount, "Overflow happened while calculating the total price of tickets. Try buying smaller number of tickets.");
        require(curEvent.maxTickets > ticketCount + curEvent.nextTicketToSell, "We don't have that many tickets left to sell!");
        require(curEvent.pricePerTicket * ticketCount <= erc20Coin.balanceOf(msg.sender), "not enough IERC20 in your account");
        require(erc20Coin.transferFrom(msg.sender, address(this), curEvent.pricePerTicketERC20 * ticketCount), "The transfer is not successful!!");
        // Buy ticket one by one
        for (uint128 i = 0; i < ticketCount; i++){
            ticketNFT.mintFromMarketPlace(msg.sender, getNftId(eventId, curEvent.nextTicketToSell + i));
        }
        // update the Event
        curEvent.nextTicketToSell += ticketCount;
        // Transfer the IERC20 to the marketplace
        emit TicketsBought(eventId, ticketCount, ERC20_TYPE);
    }

    function setERC20Address(address newERC20Address) external override{
        checkPermission(msg.sender);
        scAddress = newERC20Address;
        emit ERC20AddressUpdate(newERC20Address);
    }

    function nftContract() public view returns(TicketNFT){
        return ticketNFT;
    }

    function owner() public view returns(address){
        return tmOwnerAddress;
    }

    function ERC20Address() public view returns(address){
        return scAddress;
    }

    function currentEventId() public view returns(uint128){
        return curID;
    }





}