// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Stranger is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable, ERC721Burnable {
    using Counters for Counters.Counter;
    
    string private _basURI;
    string private _misteryURI;

    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => bool) private _isTokenOpen;
    mapping(uint256 => string) private _closedTokenDataURI;
    
    event tokenOpened(uint256 tokenId, address executor, address owner);

    constructor() ERC721("Stranger", "STG") {
        _basURI = "https://ipfs.io/ipfs/";
        _misteryURI = "QmeegrXnnfE1EkKNQmv13QmcK3XKAoYtUpbxGXxGhiAeeR?filename=box.json";
    }
    
    function setBasURL(string memory baseURI) public onlyOwner {
        _basURI = baseURI;
    }
    
    function setBoxURL(string memory boxURI) public onlyOwner {
        _misteryURI = boxURI;
    }
    
    function mint(address to, string memory contentURI, bool isOpen) public onlyOwner returns(uint256) {
        uint256 newTokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        
        _safeMint(to, newTokenId);
        _isTokenOpen[newTokenId] = isOpen;
        
        if(isOpen) {
            _setTokenURI(newTokenId, contentURI);
        }
        else {
            _setTokenURI(newTokenId, contentURI);
            _closedTokenDataURI[newTokenId] = contentURI;
        }
 
        return newTokenId;
    }
    
    function isTokenOpen(uint256 tokenId) public view returns(bool){
        return _isTokenOpen[tokenId];
    }
    
    function openMisteryBox(uint256 tokenId) public whenNotPaused {
        require(_exists(tokenId), "Intent to open non existing token");
        require(ownerOf(tokenId) == tx.origin, "Not enough ownership to open this token");
        require(_isTokenOpen[tokenId] == false, "This token is already open");
        
        _setTokenURI(tokenId, _closedTokenDataURI[tokenId]);
        delete _closedTokenDataURI[tokenId];
        
        emit tokenOpened(tokenId, msg.sender, tx.origin);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}