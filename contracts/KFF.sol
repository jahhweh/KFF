// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// These files are imported from openzeppelin's github repo.
// When the contract is live, all the functions from these contracts
// will automatically be imported into our KFF contract
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// This is the KFF contract.
contract KFF is ERC721, ERC721Enumerable, Pausable, Ownable, ERC721Burnable {
    using Strings for uint256;

    // This defines the contracts variables
    string public baseURI; // this is the URL of the folder containing the metadata
    string public baseExtension = ".json"; // this is the file extension of the metadata
    uint256 public cost = 0.1 ether; // this is the cost of minting one NFT, in wei 
    uint256 public maxSupply = 10001; // this is the maximum supply of NFTs 
    uint256 public allowMintingOn; // this is the time minting is allowed to begin, in UNIX/EPOCH time
    bool public isPaused = false; // this is the toggle to pause and unpause minting
    mapping(address => uint256) public superDonors; // this is a list that tracks the total donated eth for wallet addresses, known as the philanthropist amount
    address public receiver; // this is the beneficiary wallet
    mapping(uint256 => uint256) public hodlStart; // this is a list tracking the time a wallet received the NFT, known as hodl time

        // these are the variables required to deploy the contract
    constructor(
        string memory _name, // the name 
        string memory _symbol, // the $TOKEN name
        uint256 _allowMintingOn, // the unix/epoch date to open minting
        string memory _initBaseURI, // the url of the metadata
        address _receiver
        // deploy!
    ) ERC721(_name, _symbol) {

            // set the time minting is allowed to begin
        if (_allowMintingOn > block.timestamp) {
            allowMintingOn = _allowMintingOn;
        }
            // lock in the variables
        setBaseURI(_initBaseURI);
        receiver = _receiver;
    }

    // All of the below functions are custom for this contract, 
    // except for the two functions that are required by openzeppelin. 
    // NFTs are referred to as Tokens, one NFT is one Token

        // MINT FUNCTION
    // This will mint one token, start hodl time, set ranking to zero, 
    // and if applicable, add the wallet and amount donated to philanthropist list and philanthropist amount
    function mint(address _to) public payable {
        uint256 tokenId = totalSupply() + 1;
        require(block.timestamp >= allowMintingOn, "Minting is still turned off");
        require(tokenId <= maxSupply, "Maximum supply has been minted");
        require(!isPaused, "Minting is currently paused");
        require(msg.value >= cost, "Not enough eth");

        hodlStart[tokenId] = block.timestamp;
        _safeMint(_to, tokenId);

            // ADD TO PHILANTHROPIST LIST
        if (msg.value > cost) {
            superDonors[msg.sender] += msg.value - cost;
        }
    }

        // GET A WALLETS OWNED TOKEN IDS
    // this will search a wallet to check if they own any of this collections NFTs, and which number mint they own
    function getWalletTokenIds(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

        // GET A TOKENS METADATA LINK
    // this gets the URL to the metadata of a specific NFT
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Token number does not exist");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
                : "";
    }

        // REQUIRED BY OPENZEPPELIN FOR PAUSABLE FUNCTIONALITY
    // this function is required by Openzeppelin for implementing the pause function
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

        // REQUIRED BY OPENZEPPELIN FOR ENUMBERABLE FUNCTIONALITY
    // this function is required by Openzeppelin for implementing enumerable functionality
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

        // OVERRIDE SAFETRANSFER TO SET NEW HODLSTART
    // this function overrides the safeTransferFrom function
    // and adds "hodlStart[tokenId] = block.timestamp;"
    // to reset the hodl time when an NFT is transferred
    // to a new wallet
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721, IERC721) {
        safeTransferFrom(from, to, tokenId, "");
        hodlStart[tokenId] = block.timestamp;
    }

        // GET HODLTIME
    // this gets the total hodl time for a specific NFT, in seconds
    function getHodlTime(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Token number does not exist");
        uint256 _hodlStart = hodlStart[tokenId];
        return block.timestamp - _hodlStart;
    }

        // GET BASE URI
    // this gets the URL to the NFTs metadata
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

        // SET NEW COST FOR MINT
    // this function will change the cost of minting one NFT
    // only the contract owner can use this function
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

        // GET PHILANTHROPIST LIST
    // this checks if a wallet is on the philanthropy list
    // and the total amount donated
    function getSuperDonors(address _user) public view returns (uint256) {
        return (superDonors[_user]);
    }

        // CHANGE THE MAIN METADATA HYPERLINK
    // this changes the URL of the collections metadata
    // only the contract owner can use this function
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

        // CHANGE THE FILE EXTENSION FOR THE MAIN METADATA
    // this changes the file extension for the URL of the collections metadata
    // only the contract owner can use this function
    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

        // PAUSE AND UNPAUSE MINTING
    // this pauses and unpauses minting
    // only the contract owner can use this function
    function setIsPaused(bool _state) public onlyOwner {
        isPaused = _state;
    }

        // SET THE RECEIVER ADDRESS
    // this allows the contract owner to set the benefactor address
    function setReceiver(address _user) public onlyOwner {
        receiver = _user;
    }

        // RECEIVER WITHDRAW FUNDS FROM CONTRACT
    // this withdraws all the eth in the contract
    // only the benefactor can use this function
    function receiverWithdraw() public payable {
        (bool success, ) = payable(receiver).call{
            value: address(this).balance
        }("");
        require(success);
    }
}
