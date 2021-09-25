// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Marketplace is ReentrancyGuard, Pausable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _itemsSold;

    uint private _comissionPercentage;

    struct Listing {
        uint listingId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
        bool active;
        bool cancelled;
    }

    mapping(address => Listing[]) private _userToListings;
    mapping(address => uint256) private _addressToCustomerCounter;
    Listing[] private _listings;
    
    constructor() Pausable() Ownable() {
        _comissionPercentage = 1;
    }
    
    modifier isApproved(address nftContract, uint256 tokenId){
        require(
                (ERC721(nftContract).getApproved(tokenId) == address(this)) ||
                (ERC721(nftContract).isApprovedForAll(msg.sender, address(this))),
                "Marketplace: Marketplace is not approved to interact with this token"
            );
        _;
    }

    modifier exists(uint256 listingId) {
        require(_listings[listingId].seller != address(0), "Marketplace: Intent to interact with non existing listing");
        _;
    }

    modifier owned(uint256 listingId) {
        require(_listings[listingId].seller == msg.sender, "Marketplace: Intent to modify listing which does not own");
        _;
    }

    modifier notCancelled(uint256 listingId) {
        require(_listings[listingId].cancelled == false, "Marketplace: Intent to perform sale on listing which is cancelled");
        _;
    }

    modifier isActive(uint256 listingId) {
        require(_listings[listingId].active == true, "Marketplace: Intent to perform sale on listing which is not active");
        _;
    }

    event ItemListed(
        uint indexed listingId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold,
        bool active,
        bool cancelled
    );

    event ItemSold(
        uint indexed listingId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold,
        bool active,
        bool cancelled
    );

    function _executeTransfer(
        Listing storage listing
    ) 
        private whenNotPaused
        isApproved(listing.nftContract, listing.tokenId)
    {
        require(listing.seller != address(0), "Marketplace: Intent to transact on unexisting listing");
        require(listing.seller != msg.sender && listing.seller != tx.origin, "Marketplace: Intent to buy self owned own item");
        
        ERC721(listing.nftContract).safeTransferFrom(listing.seller, tx.origin, listing.tokenId);
        
        
        
        listing.owner = payable(tx.origin);
        listing.sold = true;
        
        _itemsSold.increment();
    }

    function createListing(
        address nftContract,
        uint256 tokenId,
        uint256 price
    )   
        public nonReentrant whenNotPaused
        isApproved(nftContract, tokenId)
    {
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
            false,
            true,
            false
        ));
        
        // Increment user counter
        _addressToCustomerCounter[tx.origin]++;
        // Push the same item to the user's collection
        _userToListings[tx.origin].push(_listings[newListingId]);

        // Authorize self to move this token

        emit ItemListed(newListingId, nftContract, tokenId, tx.origin, address(0), price, false, true, false);
    }

    function executeSale(uint256 listingId)
        public payable whenNotPaused nonReentrant
        exists(listingId)
        notCancelled(listingId)
        isActive(listingId)
    {
        Listing storage listing = _listings[listingId];
        uint finalPrice = ((listing.price * _comissionPercentage) / 100) + listing.price;

        require(msg.value >= finalPrice, "Marketplace: Value must equal to the listing price plus comission");
        
        _executeTransfer(listing);
        
        listing.seller.transfer(listing.price);
        payable(owner()).transfer(finalPrice - msg.value);
        
        emit ItemSold(listing.listingId, listing.nftContract, listing.tokenId, listing.seller, listing.owner, listing.price, true, false, false);
    }

    function cancelListing(uint256 listingId) public owned(listingId) {
        _listings[listingId].cancelled = true;
        _listings[listingId].tokenId = 0;
        _listings[listingId].nftContract = address(0);
    }

    function getComissionPercentage() public view returns(uint) {
        return _comissionPercentage;
    }

    function setComissionPercentage(uint newPercentage) public onlyOwner {
        _comissionPercentage = newPercentage;
    }

    function pauseListing(uint256 listingId) public owned(listingId) {
        _listings[listingId].active = false;
    }

    function unpauseListing(uint256 listingId) public owned(listingId) {
        _listings[listingId].active = true;
    }
    
    function getUnsoldListings() public view returns(Listing[] memory) {
        uint256 unsoldItemsNumber = _listings.length - _itemsSold.current();
        Listing[] memory unsold = new Listing[](unsoldItemsNumber);
        uint256 unsoldLength = 0;
        
        for(uint256 i = 0; i < _listings.length; i++){
            if(
                _listings[i].sold == false &&
                _listings[i].cancelled != false
            ){
                unsold[unsoldLength] = _listings[i];
                unsoldLength++;
            }
        }
        
        return unsold;
    }
    
    function getExecutedListings() public view returns(Listing[] memory) {
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
    
    function getUserListings(address user) public view whenNotPaused returns(Listing[] memory) {
        return _userToListings[user];
    }

    function getListing(uint256 listingId) public view whenNotPaused exists(listingId) returns(Listing memory) {
        return _listings[listingId];
    }

}