// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// To count each and every thing like no of tokens mint, sold, etc
import "@openzeppelin/contracts/utils/Counters.sol";
// To import properties of ERC721 Token
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// 
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

// For checking values in our console
import "hardhat/console.sol";

contract NFTMarketplace is ERC721URIStorage{
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds; // to store id of NFT & each NFT will have unique id
    Counters.Counter private _itemsSold; // to track how many tokens are sold

    uint256 listingPrice = 0.0025 ether;  //price charged on listing NFT

    address payable owner; // to owners address and its payable so that it can recive funds

    mapping(uint256 => MarketItem) private idMarketItem; // Mapping NFT (MarketItem) with idMarketItem as a Key

    // Struct to store all details of NFT
    struct MarketItem {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold; // for checking status that NFT is sold or not
    }

    event idMarketItemCreated(
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    // to set only owner of this smart contract as modifier, who can only change the listing price of NFT.
    modifier onlyOwner{
        require(
            msg.sender == owner,
            "only owner of the marketplace can change the listing price"
        );
        _;
    }

    constructor() ERC721("NFT Metavarse Token", "MyNFT"){ //this is written in ERC721.sol and we just have to pass name and symbol as argument
        owner == payable(msg.sender);
    }

    function updateListingPrice(uint256 _ListingPrice) public payable onlyOwner{
        listingPrice = _ListingPrice;
    }

    function getListingPrice() public view returns(uint256){
        return listingPrice;
    }

    //NFT Token function
    function createToken(string memory tokenURI, uint256 price) public payable returns(uint256){
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _mint (msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        createMarketItem(newTokenId, price);

        return newTokenId;
    }

    //Function to creating marketItem(NFT)
    function createMarketItem(uint256 tokenId, uint price ) private{
        require(price > 0, "Price must be greate than 0");
        require(msg.value == listingPrice, "Price must be equal to Listing price");

        idMarketItem[tokenId] = MarketItem(
            tokenId,
            payable(msg.sender),
            payable(address(this)),
            price,
            false
        );

        _transfer(msg.sender, address(this), tokenId);

        emit idMarketItemCreated(tokenId, msg.sender, address(this), price, false);
    }


    // Function for resale token(NFT)
    function reSellToken(uint256 tokenId, uint256 price) public payable{
        require(idMarketItem[tokenId].owner == msg.sender, "only item owner can sell");

        idMarketItem[tokenId].sold = false;
        idMarketItem[tokenId].price = price;
        idMarketItem[tokenId].seller = payable(msg.sender);
        idMarketItem[tokenId].owner = payable(address(this));

        _itemsSold.decrement();

        _transfer(msg.sender, address(this), tokenId);
    }

    // Function too createmarketsale
    function createMarketSale(uint256 tokenId) public payable{
        uint256 price = idMarketItem[tokenId].price;

        require(
            msg.value == price,
            "Pls submit the asking price in order to complete the purchase"
        );

        idMarketItem[tokenId].owner = payable(msg.sender);
        idMarketItem[tokenId].sold = true;
        idMarketItem[tokenId].owner = payable(address(0));

        _itemsSold.increment();

        _transfer(address(this), msg.sender, tokenId);

        payable(owner).transfer(listingPrice);
        payable(idMarketItem[tokenId].seller).transfer(msg.value);
    }

    // Function to get unsold NFT data
    function fetchMarketItem() public view returns(MarketItem[] memory){
        uint256 itemCount = _tokenIds.current();
        uint256 unSoldItemCount = _tokenIds.current() - _itemsSold.current();

        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unSoldItemCount);

        for(uint256 i = 0;i<itemCount;i++){
            if(idMarketItem[i+1].owner == address(this)){
                uint256 currentId = i + 1;

                MarketItem storage currentItem = idMarketItem[currentId];

                items[currentIndex] = currentItem;
                currentIndex += 1;                
            }
        }
        return items;
    }

    // Function to get Purchased NFT
    function fetchMyNFT() public view returns (MarketItem[] memory){
        uint256 totalCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for(uint256 i=0;i<totalCount;i++){
            if(idMarketItem[i+1].owner == msg.sender){
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for(uint256 i =0;i<totalCount;i++){
            if(idMarketItem[i+1].owner == msg.sender){
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            } 
        }
        return items;
    }

    
    // Single users item
    function fetchItemsListed() public view returns(MarketItem[] memory){
        uint256 totalCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for(uint256 i=0; i<totalCount; i++){
            if(idMarketItem[i+1].seller == msg.sender){
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for(uint256 i =0; i<totalCount; i++){
            if(idMarketItem[i+1].seller == msg.sender){
                uint256 currentId = i+1;

                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items; 
    }

}






