// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@dirtycajunrice/contracts/utils/access/StandardAccessControl.sol";
import "@dirtycajunrice/contracts/third-party/chainlink/ChainlinkVRFConsumer.sol";

import "../Cue/I8BallCue.sol";
import "./I8BallCueMinter.sol";

/**
* @title Arcadian 8Ball Cue Minter v2.0.0
* @author @DirtyCajunRice
*/
contract A8BallCueMinter is Initializable, I8BallCueMinter, PausableUpgradeable, UUPSUpgradeable,
ReentrancyGuardUpgradeable, StandardAccessControl, ChainlinkVRFConsumer {
    /*************
     * Libraries *
     *************/

    using CountersUpgradeable for CountersUpgradeable.Counter;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    /*************
     * Variables *
     *************/

    // Public

    // Treasury address
    address public treasury;
    // 8BallCue address
    address public cue;
    // skill point upgrade cost
    uint256 public upgradePrice;

    // Private
    uint256 private constant BASIS_POINTS = 10_000;

    // Complex

    // collectionIds
    EnumerableSetUpgradeable.UintSet private _collectionIds;
    // collectionId => Collection
    mapping (uint256 => Collection) private _collections;
    // tokenId counter for 8BallCue
    CountersUpgradeable.Counter private _counter;
    // wallet => credits | 1 credit is worth 1 cue.
    mapping (address => uint256) public credits;
    /*************
     * Construct *
     *************/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Pausable_init();
        __StandardAccessControl_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __ERC165_init();
        __ChainlinkVRFConsumer_init(
            0x2eD832Ba664535e5886b75D64C46EB9a228C2610, // coordinator (Fuji)
            // 0xd5D517aBE5cF79B7e95eC98dB0f0277788aFF634, // coordinator (Avalanche)
            0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61, // key hash (Fuji) (300 Gwei)
            // 0x83250c5584ffa93feb6ee082981c5ebe484c865196750b39835ad4f13780435d, // key hash (Avalanche) (200 Gwei)
            526, // subscription ID (Fuji)
            // 103, // subscription ID (Avalanche)
            1 // confirmations
        );

        upgradePrice = 1 ether / 2;
        cue = 0xCd9Df581F855d07144F150B0C681824548008644; // Fuji
        // cue = 0xEcC82f602a7982a9464844DEE6dBc751E3615BB4; // Avalanche

        _counter.increment();
    }

    /*************
     * Functions *
     *************/

    function buyRandomCue(uint256 collectionId) external payable whenNotPaused nonReentrant {
        _beforePurchase(collectionId);
        uint256[] memory links = new uint256[](3);
        links[0] = collectionId;
        links[1] = _nextTokenID();
        links[2] = _processPayment(collectionId);
        _requestRandom(msg.sender, 1, links);
        _beforePurchase(collectionId);
    }

    function mintRandomCue() external whenNotPaused nonReentrant {
        (uint256[] memory words, uint256[] memory links) = _consumeRequest(msg.sender);
        require(words.length > 0, "8BallCueMinter::Request is still pending");

        // roll for design & decrement total
        uint256 designId = _randDesignId(links[0], _collections[links[0]].designIds.values(), words[0]);
        _afterPurchase(links[0], designId, links[2], links[1]);
    }

    function mintSpecificCue(uint256 collectionId, uint256 designId) external payable whenNotPaused nonReentrant {
        _beforePurchase(collectionId);
        require(!_collections[collectionId].random, "8BallCueMinter::Invalid specific mint collection");
        require(_collections[collectionId].designIds.contains(designId), "8BallCueMinter::Invalid designId");
        // payment
        _afterPurchase(collectionId, designId, _processPayment(collectionId), _nextTokenID());
    }

    function upgradeCue(
        uint256 tokenId,
        uint256 power,
        uint256 accuracy,
        uint256 spin,
        uint256 time
    ) external payable whenNotPaused nonReentrant {
        I8BallCue _cue = I8BallCue(cue);
        Cue memory cue_ = _cue.getCue(tokenId);
        uint256 max = cue_.rarity == Rarity.Common ? 5 : 6 + uint256(cue_.rarity);
        uint256 cost = (power + accuracy + spin + time) * upgradePrice;

        require(msg.value >= cost, "8BallCueMinter::Insufficient payment");
        payable(treasury).transfer(cost);

        cue_.power += power;
        cue_.accuracy += accuracy;
        cue_.spin += spin;
        cue_.time += time;
        require(
            cue_.power <= max && cue_.accuracy <= max && cue_.spin <= max && cue_.time <= max,
            "8BallCueMinter::Invalid upgrade amounts"
        );
        _cue.upgradeCue(msg.sender, tokenId, cue_);

        emit CueUpgraded(msg.sender, tokenId, cue_.collectionId, cue_.rarity, cost);
    }

    function getMintPrice(uint256 collectionId) public view returns (uint256) {
        uint256 discount = 0;
        Collection storage collection = _collections[collectionId];
        if (collection.mintConfig.startTime + collection.allowlistConfig.duration > block.timestamp) {
            if (collection.allowlist.contains(msg.sender)) {
                discount = collection.mintConfig.price * collection.allowlistConfig.discount / BASIS_POINTS;
            }
        }
        return collection.mintConfig.price - discount;
    }

    function setTreasury(address _treasury) external onlyAdmin {
        require(_treasury != address(0) && _treasury != treasury, "8BallCueMinter::Invalid treasury address");
        treasury = _treasury;
    }

    function addCollection(
        uint256 collectionId,
        string calldata name,
        MintConfig calldata mintConfig,
        AllowlistConfig calldata allowlistConfig,
        bool random,
        bool exists
    ) external onlyAdmin {
        require(_collectionIds.add(collectionId), "8BallCueMinter::Existing collection ID");
        Collection storage collection = _collections[collectionId];
        collection.mintConfig = mintConfig;
        collection.allowlistConfig = allowlistConfig;
        collection.random = random;
        if (!exists) {
            I8BallCue(cue).addCollection(collectionId, name);
        }
    }

    function addCollectionDesigns(uint256 collectionId, Design[] calldata designs) external onlyAdmin {
        require(_collectionIds.contains(collectionId), "8BallCueMinter::Non-existent collectionId");
        Collection storage collection = _collections[collectionId];
        for (uint256 i = 0; i < designs.length; i++) {
            collection.designIds.add(designs[i].id);
            collection.designs[designs[i].id] =  DesignBase(designs[i].rarity, designs[i].remaining);
        }
        I8BallCue(cue).addCollectionDesigns(collectionId, designs);
    }

    function setCollectionRoyaltyConfig(uint256 collectionId, RoyaltyConfig calldata config) external onlyAdmin {
        require(_collectionIds.contains(collectionId), "8BallCueMinter::Non-existent collectionId");
        require(
            (config.basisPoints == 0 && config.treasury == address(0))
            || (config.basisPoints != 0 && config.treasury != address(0)),
            "8BallCueMinter::Invalid royalty config"
        );

        Collection storage collection = _collections[collectionId];
        collection.royaltyConfig = config;
    }

    function setCollectionMintConfig(uint256 collectionId, MintConfig calldata config) external onlyAdmin {
        require(_collectionIds.contains(collectionId), "8BallCueMinter::Non-existent collectionId");
        require(config.startTime > block.timestamp, "8BallCueMinter::Invalid mint startTime");
        require(config.price > 0, "8BallCueMinter::Invalid mint price");
        Collection storage collection = _collections[collectionId];
        collection.mintConfig = config;
    }

    function setCollectionAllowlistConfig(uint256 collectionId, AllowlistConfig calldata config) external onlyAdmin {
        require(_collectionIds.contains(collectionId), "8BallCueMinter::Non-existent collectionId");
        require(
            (config.discount == 0 && config.duration == 0) || (config.discount != 0 && config.duration != 0),
            "8BallCueMinter::Invalid royalty config"
        );
        require(config.discount < BASIS_POINTS, "8BallCueMinter::Invalid allowlist discount");

        Collection storage collection = _collections[collectionId];
        collection.allowlistConfig = config;
    }

    function addToCollectionAllowlist(uint256 collectionId, address[] calldata wallets) external onlyAdmin {
        require(_collectionIds.contains(collectionId), "8BallCueMinter::Non-existent collectionId");
        require(wallets.length > 0, "8BallCueMinter::Empty wallet list");
        Collection storage collection = _collections[collectionId];
        for (uint256 i = 0; i < wallets.length; i++) {
            collection.allowlist.add(wallets[i]);
        }
    }

    function removeFromCollectionAllowlist(uint256 collectionId, address[] calldata wallets) external onlyAdmin {
        require(_collectionIds.contains(collectionId), "8BallCueMinter::Non-existent collectionId");
        require(wallets.length > 0, "8BallCueMinter::Empty wallet list");
        Collection storage collection = _collections[collectionId];
        for (uint256 i = 0; i < wallets.length; i++) {
            collection.allowlist.remove(wallets[i]);
        }
    }

    function setCollectionRandom(uint256 collectionId, bool random) external onlyAdmin {
        require(_collectionIds.contains(collectionId), "8BallCueMinter::Non-existent collectionId");
        Collection storage collection = _collections[collectionId];
        collection.random = random;
    }

    function addCredits(address wallet, uint256 _credits) external onlyAdmin {
        if (credits[wallet] + _credits > 100) {
            credits[wallet] = 100;
        } else {
            credits[wallet] += _credits;
        }
    }

    function removeCredits(address wallet, uint256 _credits) external onlyAdmin {
        if (credits[wallet] < _credits) {
            credits[wallet] = 0;
        } else {
            credits[wallet] -= _credits;
        }
    }

    function getCollectionIds() external view returns (uint256[] memory) {
        return _collectionIds.values();
    }

    function getCollectionRoyaltyConfig(uint256 collectionId) external view returns (RoyaltyConfig memory) {
        require(_collectionIds.contains(collectionId), "8BallCueMinter::Non-existent collectionId");
        return _collections[collectionId].royaltyConfig;
    }

    function getCollectionMintConfig(uint256 collectionId) external view returns (MintConfig memory) {
        require(_collectionIds.contains(collectionId), "8BallCueMinter::Non-existent collectionId");
        return _collections[collectionId].mintConfig;
    }

    function getCollectionAllowlistConfig(uint256 collectionId) external view returns (AllowlistConfig memory) {
        require(_collectionIds.contains(collectionId), "8BallCueMinter::Non-existent collectionId");
        return _collections[collectionId].allowlistConfig;
    }

    function getCollectionAllowlist(uint256 collectionId) external view returns (address[] memory) {
        require(_collectionIds.contains(collectionId), "8BallCueMinter::Non-existent collectionId");
        return _collections[collectionId].allowlist.values();
    }

    function getCollectionRandom(uint256 collectionId) external view returns (bool) {
        require(_collectionIds.contains(collectionId), "8BallCueMinter::Non-existent collectionId");
        return _collections[collectionId].random;
    }

    function getCollectionDesignIds(uint256 collectionId) external view returns (uint256[] memory) {
        require(_collectionIds.contains(collectionId), "8BallCueMinter::Non-existent collectionId");
        return _collections[collectionId].designIds.values();
    }

    function getCollectionDesign(uint256 collectionId, uint256 designId) external view returns (DesignBase memory) {
        require(_collectionIds.contains(collectionId), "8BallCueMinter::Non-existent collectionId");
        Collection storage collection = _collections[collectionId];
        require(collection.designIds.contains(designId), "8BallCueMinter::Non-existent or sold-out designId");
        return collection.designs[designId];
    }

    function isAllowlisted(uint256 collectionId, address wallet) external view returns (bool) {
        require(_collectionIds.contains(collectionId), "8BallCueMinter::Non-existent collectionId");
        return _collections[collectionId].allowlist.contains(wallet);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyAdmin {}

    function pause() external onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin {
        _unpause();
    }

    function setCounter(uint256 value) external onlyAdmin {
        _counter._value = value;
    }

    function setCue(address _cue) external onlyAdmin {
        cue = _cue;
    }

    function _processPayment(uint256 collectionId) internal returns (uint256) {
        if (credits[msg.sender] > 0) {
            credits[msg.sender]--;
            return 0;
        }
        uint256 total = getMintPrice(collectionId);
        uint256 balance = total;
        require(msg.value >= total, "8BallCueMinter::Insufficient payment");
        RoyaltyConfig storage royalty = _collections[collectionId].royaltyConfig;
        if (royalty.treasury != address(0)) {
            uint256 shared = total * royalty.basisPoints / BASIS_POINTS;
            balance -= shared;
            (bool sent,) = treasury.call{value: shared}("");
            if (sent) {
                emit RoyaltyPaid(msg.sender, royalty.treasury, collectionId, shared);
            } else {
                emit RoyaltyShareFailed(msg.sender, royalty.treasury, collectionId, shared);
            }
        }

        payable(treasury).transfer(balance);
        return total;
    }

    function _randDesignId(
        uint256 collectionId, uint256[] memory designIds, uint256 rand
    ) internal view returns (uint256) {
        // sum remaining across all design ids;
        uint256 sum = 0;
        for (uint256 i = 0; i < designIds.length; i++) {
            sum += _collections[collectionId].designs[designIds[i]].remaining;
        }
        // result evenly split across all remaining
        uint256 result = rand % sum;
        sum = 0;
        // Iterate remaining until sum is greater than result
        for (uint256 i = 0; i < designIds.length; i++) {
            uint256 max = sum + _collections[collectionId].designs[designIds[i]].remaining;
            if (result <= (max - 1)) {
                return designIds[designIds[i]];
            }
            sum = max;
        }
        revert("8BallCueMinter::Error calculating random designId");
    }

    function _nextTokenID() internal returns(uint256) {
        // save and increment the tokenId counter
        uint256 tokenId = _counter.current();
        _counter.increment();
        return tokenId;
    }

    function _beforePurchase(uint256 collectionId) internal view {
        // checks
        require(_collectionIds.contains(collectionId), "8BallCueMinter::Non-existent collectionId");
        require(
            block.timestamp >= _collections[collectionId].mintConfig.startTime || _hasAdminRole(msg.sender),
            "8BallCueMinter::Mint has not started"
        );
        require(_collections[collectionId].designIds.length() > 0, "8BallCueMinter::Sold out");
    }

    function _afterPurchase(uint256 collectionId, uint256 designId, uint256 payment, uint256 tokenId) internal {
        Collection storage collection = _collections[collectionId];
        DesignBase storage design = collection.designs[designId];
        design.remaining--;
        if (design.remaining == 0) {
            collection.designIds.remove(designId);
        }
        // mint cue;
        I8BallCue(cue).mint(msg.sender, tokenId, Cue(design.rarity, collectionId, designId, 1, 1, 1, 1));

        emit CuePurchased(msg.sender, tokenId, collectionId, design.rarity, payment);
    }


    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ChainlinkVRFConsumer, AccessControlEnumerableUpgradeable) returns (bool){
        return type(I8BallCueMinter).interfaceId == interfaceId || super.supportsInterface(interfaceId);
    }
}