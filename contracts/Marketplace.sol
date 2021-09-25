// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Marketplace is ReentrancyGuard {
    using Counters for Counters.Counter;

    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;

    address owner;
    
    constructor() {
        owner = msg.sender;
    }
}