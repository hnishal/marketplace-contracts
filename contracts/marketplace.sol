// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "hardhat/console.sol";

contract NFTMarket is
    Initializable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    AccessControlUpgradeable
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _itemIds;
    CountersUpgradeable.Counter private _itemsSold;

    address payable owner;
    address payable _pay;

    // constructor() {
    //     owner = payable(msg.sender);
    //     _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    //     _pay = owner;
    // }

    function initialize() public initializer {
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __AccessControl_init();
        // MINTER_ROLE = keccak256("MINTER_ROLE");
        owner = payable(msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(MINTER_ROLE, DEFAULT_ADMIN_ROLE);
        _pay = owner;
    }

    struct MarketItem {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
        bool locked;
    }

    mapping(uint256 => MarketItem) private idToMarketItem;

    event MarketItemCreated(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold,
        bool locked
    );

    function updatePay(address payable pay) public {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        _pay = pay;
    }

    function checkPay() public view returns (address) {
        return _pay;
    }

    function createMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) public payable nonReentrant {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        require(price > 0, "Price must be at least 1 wei");

        _itemIds.increment();
        uint256 itemId = _itemIds.current();

        idToMarketItem[itemId] = MarketItem(
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            false,
            false
        );

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        emit MarketItemCreated(
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            price,
            false,
            false
        );
    }

    function createMarketSale(address nftContract, uint256 itemId)
        public
        payable
        nonReentrant
    {
        uint256 price = idToMarketItem[itemId].price;
        uint256 tokenId = idToMarketItem[itemId].tokenId;
        require(
            msg.value == price,
            "Please submit the asking price in order to complete the purchase"
        );
        require(idToMarketItem[itemId].locked == false, "Item is locked");
        _pay.transfer(msg.value);
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        idToMarketItem[itemId].owner = payable(msg.sender);
        idToMarketItem[itemId].sold = true;
        _itemsSold.increment();
    }

    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint256 itemCount = _itemIds.current();
        uint256 unsoldItemCount = _itemIds.current() - _itemsSold.current();
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            if (
                idToMarketItem[i + 1].owner == address(0) &&
                idToMarketItem[i + 1].locked == false
            ) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function fetchMyNFTs() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _itemIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function fetchItemsCreated() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _itemIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function lockItem(uint256 itemId) public nonReentrant {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        require(
            idToMarketItem[itemId].locked != true,
            "Item is already locked"
        );
        idToMarketItem[itemId].locked = true;
    }

    function unLockItem(uint256 itemId) public nonReentrant {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        require(
            idToMarketItem[itemId].locked != false,
            "Item is already unlocked"
        );
        idToMarketItem[itemId].locked = false;
    }

    function getItem(uint256 itemId) public view returns (MarketItem memory) {
        return idToMarketItem[itemId];
    }

    function _authorizeUpgrade(address newImplementation) internal override {}
}
