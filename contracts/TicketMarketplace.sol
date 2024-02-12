// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ITicketNFT} from "./interfaces/ITicketNFT.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TicketNFT} from "./TicketNFT.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol"; 
import {ITicketMarketplace} from "./interfaces/ITicketMarketplace.sol";
import "hardhat/console.sol";

contract TicketMarketplace is ITicketMarketplace {
    // your code goes here (you can do it!)
    mapping(uint128 => Event) public events;
    
    TicketNFT public ticketNFT;    
    address owner_market;
    address add_erc20;
    uint128 cureventid;

    struct Event{
        uint256 pricePerTicket;
        uint256 pricePerTicketERC20;
        uint128 maxTickets;
        uint128 nextTicketToSell;
    }

    constructor(address _adrerc20){
        add_erc20 = _adrerc20;
        ticketNFT = new TicketNFT(address(this));
        cureventid = 0;
        owner_market = msg.sender;
    }

    function createEvent(uint128 maxTickets, uint256 pricePerTicket, uint256 pricePerTicketERC20) external override{
        if (msg.sender != owner_market){
            revert("Unauthorized access");
        }
        events[cureventid] = Event(pricePerTicket,pricePerTicketERC20,maxTickets,0);
        emit EventCreated(cureventid,maxTickets,pricePerTicket,pricePerTicketERC20);
        cureventid +=1;
    }

    function setMaxTicketsForEvent(uint128 eventId, uint128 newMaxTickets)external {
        if (msg.sender != owner_market){
            revert("Unauthorized access");
        }
        if (events[eventId].nextTicketToSell >= newMaxTickets) {
            revert("The new number of max tickets is too small!");
        }
        if (events[eventId].maxTickets >= newMaxTickets) {
            revert("The new number of max tickets is too small!");
        }
        events[eventId].maxTickets = newMaxTickets;
        emit MaxTicketsUpdate(eventId, newMaxTickets);
    }

    function setPriceForTicketETH(uint128 eventId, uint256 price) external{
        if (msg.sender != owner_market){
            revert("Unauthorized access");
        }
        events[eventId].pricePerTicket= price;
        emit PriceUpdate(eventId, price, "ETH");
    }

    function setPriceForTicketERC20(uint128 eventId, uint256 price) external{
        if (msg.sender != owner_market){
            revert("Unauthorized access");
        }
        events[eventId].pricePerTicketERC20 = price;
        emit PriceUpdate(eventId, price, "ERC20");
    }

    function buyTickets(uint128 eventId, uint128 ticketCount) payable external{
        if (ticketCount > type(uint256).max / events[eventId].pricePerTicket) {
            revert("Overflow happened while calculating the total price of tickets. Try buying smaller number of tickets.");
        }
        if (events[eventId].pricePerTicket * ticketCount > msg.value) {
            revert("Not enough funds supplied to buy the specified number of tickets.");
        }
        if (events[eventId].nextTicketToSell+ ticketCount > events[eventId].maxTickets) {
            revert("We don't have that many tickets left to sell!");
        }
        for (uint128 i = 0; i < ticketCount; i++) {
            uint256 seatId = events[eventId].nextTicketToSell + i;
            uint256 eventId256 = eventId;
            ticketNFT.mintFromMarketPlace(
                msg.sender,
                (eventId256 << 128) + seatId
            );
        }
        events[eventId].nextTicketToSell += ticketCount;
        emit TicketsBought(eventId, ticketCount, "ETH");

    }

    function buyTicketsERC20(uint128 eventId, uint128 ticketCount) external{
        if (ticketCount > type(uint256).max / events[eventId].pricePerTicketERC20) {
            revert("Overflow happened while calculating the total price of tickets. Try buying smaller number of tickets.");
        }
        IERC20 erc20 = IERC20(add_erc20);
        if (erc20.balanceOf(msg.sender) <    events[eventId].pricePerTicketERC20 * ticketCount) {
            revert(
                "Not enough funds supplied to buy the specified number of tickets."
            );
        }
        if (
            events[eventId].nextTicketToSell + ticketCount > events[eventId].maxTickets
        ) {
            revert("We don't have that many tickets left to sell!");
        }
        for (uint128 i = 0; i < ticketCount; i++) {
            erc20.transferFrom(
                msg.sender,
                address(this),
                events[eventId].pricePerTicketERC20
            );
            uint256 seatId = events[eventId].nextTicketToSell + i;
            uint256 eventId256 = eventId;
            ticketNFT.mintFromMarketPlace(
                msg.sender,
                (eventId256 << 128) + seatId
            );
        }
        events[eventId].nextTicketToSell += ticketCount;
        emit TicketsBought(eventId, ticketCount, "ERC20");

    }

    function setERC20Address(address newERC20Address) external{
        if (msg.sender != owner_market){
            revert("Unauthorized access");
        }
        add_erc20 = newERC20Address;
        emit ERC20AddressUpdate(add_erc20);
    }

    
    function nftContract() external view returns (TicketNFT) {
        return ticketNFT;
    }
    function owner() external view returns (address) {
        return owner_market;
    }
    function currentEventId() external view returns (uint128) {
        return cureventid;
    }
    function ERC20Address() public view returns (address) {
        return add_erc20;
    }
}