// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Marketplace is ReentrancyGuard {
    using Counters for Counters.Counter;

    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;

    address payable private _owner;

    struct Listing {
        uint itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    mapping(address => Listing[]) private _userToItems;
    mapping(uint256 => Listing) private _idToListing;
    mapping(address => uint256) private _addressToCustomerCounter;
    
    constructor() {
        _owner = payable(msg.sender);
    }

    event ItemListed(
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    event ItemSold(
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    function createListing(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) public nonReentrant {
        require(price >= 0, "Price cannot be negative");

        uint256 newItemId = _itemIds.current();
        _itemIds.increment();

        // Create new Listing record
        _idToListing[newItemId] = Listing(
            newItemId,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            false
        );
        
        // Increment user counter
        _addressToCustomerCounter[tx.origin]++;
        // Push the same item to the user's collection
        _userToItems[tx.origin].push(_idToListing[newItemId]);

        // Authorize self to move this token
        ERC721(nftContract).approve(address(this), tokenId);

        emit ItemListed(newItemId, nftContract, tokenId, tx.origin, address(0), price, false);
    }

    function executePurchase(uint256 listingId) public nonReentrant {
        
    }

}