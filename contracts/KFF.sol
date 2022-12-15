// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract KFF is ERC721, ERC721Enumerable, Pausable, Ownable, ERC721Burnable {
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";
    uint256 public cost = 100000000000000000;
    uint256 public maxSupply = 10001;
    uint256 public timeDeployed;
    uint256 public allowMintingAfter;
    bool public isPaused = false;
    mapping(address => bool) public philanthropistList;
    mapping(address => uint256) public philanthropistAmount;
    address public receiverOne = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
    mapping(uint256 => uint256) public hodlStart;
    mapping(uint256 => string) public roles;
    mapping(uint256 => uint256) public ranking;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _allowMintingOn,
        string memory _initBaseURI
        
    ) ERC721(_name, _symbol) {
        if (_allowMintingOn > block.timestamp) {
            allowMintingAfter = _allowMintingOn - block.timestamp;
        }
        cost = cost;
        maxSupply = maxSupply;
        timeDeployed = block.timestamp;
        setBaseURI(_initBaseURI);
    }

        // FANCY MINT FUNCTION
    function mint(address _to, uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(block.timestamp >= timeDeployed + allowMintingAfter, "Minting is still turned off");
        require(_mintAmount > 0, "Mint must be greater than zero");
        require(supply + _mintAmount <= maxSupply, "Maximum supply has been minted");
        require(!isPaused, "Minting is currently paused");
        require(msg.value >= cost * _mintAmount, "Not enough eth");

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_to, supply + i);
        }

            // INITIALIZE HODLSTART
        for (uint256 j = 1; j <= _mintAmount; j++) {
            hodlStart[supply + j] = block.timestamp;
        }

            // INITIALIZE RANKING (EVERY TOKEN IS MINTED AS RANK 0)
        for (uint256 k = 1; k <= _mintAmount; k++) {
            ranking[supply + k] = 0;
        }

            // INITIALIZE ROLES (EVERY TOKEN IS MINTED AS NO ROLE)
        for (uint256 l = 1; l <= _mintAmount; l++) {
            roles[supply + l] = "No Role";
        }

            // ADD TO PHILANTHROPIST LIST
        if (msg.value > cost * _mintAmount) {
            philanthropistList[msg.sender] = true;
            philanthropistAmount[msg.sender] = msg.value - (cost * _mintAmount);
        }
            // SPLIT PAYMENTS -- NEEDS TESTING
        payable(receiverOne).transfer(msg.value);
    }

        // GET A WALLETS OWNED TOKEN IDS
    function getWalletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

        // GET A TOKENS METADATA LINK
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Token number does not exist");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
                : "";
    }

        // REQUIRED BY OPENZEPPELIN
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

        // REQUIRED BY OPENZEPPELIN
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

        // OVERRIDE SAFETRANSFER TO SET NEW HODLSTART
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721, IERC721) {
        safeTransferFrom(from, to, tokenId, "");
        hodlStart[tokenId] = block.timestamp;
    }

        // GET HODLTIME
    function getHodlTime(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Token number does not exist");
        uint256 _hodlStart = hodlStart[tokenId];
        return block.timestamp - _hodlStart;
    }

        // GET RANKING AND ROLE
    function getRankingAndRole(uint256 tokenId) public view returns (uint256, string memory) {
        require(_exists(tokenId), "Token number does not exist");
        return (ranking[tokenId], roles[tokenId]);
    }

        // SET ROLE/TITLE
    function setRole(uint256 tokenId, uint256 _ranking, string memory _roles) public payable onlyOwner {
        require(_exists(tokenId), "Token number does not exist");
        require(msg.sender == owner(), "You are not the owner");
        ranking[tokenId] = _ranking;
        roles[tokenId] = _roles;
    }

        // GET BASE URI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

        // SET NEW COST FOR MINT
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

        // GET PHILANTHROPIST LIST
    function getPhilanthropistList(address _user) public view returns (bool, uint256) {
        return (philanthropistList[_user], philanthropistAmount[_user]);
    }

        // CHANGE THE MAIN METADATA HYPERLINK
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

        // CHANGE THE FILE EXTENSION FOR THE MAIN METADATA
    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

        // PAUSE AND UNPAUSE MINTING
    function setIsPaused(bool _state) public onlyOwner {
        isPaused = _state;
    }

        // WITHDRAW FUNDS FROM CONTRACT
    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}
