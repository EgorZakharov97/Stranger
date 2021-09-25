// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Marketplace is ReentrancyGuard, Pausable {
    using Counters for Counters.Counter;

    Counters.Counter private _itemsSold;

    address payable private _owner;

    struct Listing {
        uint listingId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    mapping(address => Listing[]) private _userToListings;
    mapping(address => uint256) private _addressToCustomerCounter;
    Listing[] private _listings;
    
    constructor() Pausable() {
        _owner = payable(msg.sender);
    }
    
    modifier isApproved(address nftContract, uint256 tokenId){
        require(
                (ERC721(nftContract).getApproved(tokenId) == address(this)) ||
                (ERC721(nftContract).isApprovedForAll(msg.sender, address(this))),
                "Marketplace: Marketplace is not approved to interact with this token"
            );
        _;
    }

    event ItemListed(
        uint indexed listingId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    event ItemSold(
        uint indexed listingId,
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
    ) public nonReentrant whenNotPaused isApproved(nftContract, tokenId) {
        require(price >= 0, "Price cannot be negative");

        uint256 newListingId = _listings.length;

        // Create new Listing record
        _listings.push(Listing(
            newListingId,
            nftContract,
            tokenId,
            payable(tx.origin),
            payable(address(0)),
            price,
            false
        ));
        
        // Increment user counter
        _addressToCustomerCounter[tx.origin]++;
        // Push the same item to the user's collection
        _userToListings[tx.origin].push(_listings[newListingId]);

        // Authorize self to move this token

        emit ItemListed(newListingId, nftContract, tokenId, tx.origin, address(0), price, false);
    }

    function executeSale(uint256 listingId) public payable whenNotPaused nonReentrant {
        Listing storage listing = _listings[listingId];
        
        _executeTransfer(listing);
        
        listing.owner.transfer(listing.price);
        
        emit ItemSold(listing.listingId, listing.nftContract, listing.tokenId, listing.seller, listing.owner, listing.price, true);
    }
    
    function _executeTransfer(
        Listing storage listing
        ) private whenNotPaused nonReentrant isApproved(listing.nftContract, listing.tokenId) {
            require(listing.seller != address(0), "Intent to transact on unexisting listing");
            require(msg.value >= listing.price, "Value must equal to the listing price");
            
            ERC721(listing.nftContract).safeTransferFrom(listing.seller, tx.origin, listing.tokenId);
            
            
            
            listing.owner = payable(tx.origin);
            listing.sold = true;
            
            _itemsSold.increment();
        }
    
    function getUnsold() public view returns(Listing[] memory) {
        uint256 unsoldItemsNumber = _listings.length - _itemsSold.current();
        Listing[] memory unsold = new Listing[](unsoldItemsNumber);
        uint256 unsoldLength = 0;
        
        for(uint256 i = 0; i < _listings.length; i++){
            if(_listings[i].sold == false){
                unsold[unsoldLength] = _listings[i];
                unsoldLength++;
            }
        }
        
        return unsold;
    }
    
    function getSold() public view returns(Listing[] memory) {
        uint256 soldItemsNumber = _itemsSold.current();
        Listing[] memory sold = new Listing[](soldItemsNumber);
        uint256 soldLength = 0;
        
        for(uint256 i = 0; i < _listings.length; i++){
            if(_listings[i].sold == true){
                sold[soldLength] = _listings[i];
                soldLength++;
            }
        }
        
        return sold;
    }
    
    function countListings() public view returns(uint256) {
        return _listings.length;
    }
    
    function countSold() public view returns(uint256) {
        return _itemsSold.current();
    }
    
    function getMyListings() public view returns(Listing[] memory) {
        return _userToListings[msg.sender];
    }
    
    function getListingsByAddress(address user) public view whenNotPaused returns(Listing[] memory) {
        return _userToListings[user];
    }

}