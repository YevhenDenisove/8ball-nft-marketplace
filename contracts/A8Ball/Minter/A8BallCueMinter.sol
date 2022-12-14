// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@dirtycajunrice/contracts/utils/access/StandardAccessControl.sol";

import "../Cue/I8BallCue.sol";
import "./I8BallCueMinter.sol";

/**
* @title Arcadian 8Ball Cue Minter v1.0.0
* @author @DirtyCajunRice
*/
contract A8BallCueMinter is Initializable, I8BallCueMinter, PausableUpgradeable, UUPSUpgradeable,
ReentrancyGuardUpgradeable, StandardAccessControl  {
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

        upgradePrice = 1 ether / 2;
        cue = 0xEcC82f602a7982a9464844DEE6dBc751E3615BB4;

        _counter.increment();
    }

    /*************
     * Functions *
     *************/

    function mintRandomCue(uint256 collectionId) external payable whenNotPaused nonReentrant {
        _beforeMint(collectionId);
        require(_collections[collectionId].random, "8BallCueMinter::Invalid random mint collection");
        uint256 payment = _processPayment(collectionId);
        // roll for design & decrement total
        uint256 designId = _randDesignId(_collections[collectionId].designIds.values());
        _afterMint(collectionId, designId, payment);
    }

    function mintSpecificCue(uint256 collectionId, uint256 designId) external payable whenNotPaused nonReentrant {
        _beforeMint(collectionId);
        require(!_collections[collectionId].random, "8BallCueMinter::Invalid specific mint collection");
        require(_collections[collectionId].designIds.contains(designId), "8BallCueMinter::Invalid designId");
        // payment
        uint256 payment = _processPayment(collectionId);
        _afterMint(collectionId, designId, payment);
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
        bool random
    ) external onlyAdmin {
        require(_collectionIds.add(collectionId), "8BallCueMinter::Existing collection ID");
        Collection storage collection = _collections[collectionId];
        collection.mintConfig = mintConfig;
        collection.allowlistConfig = allowlistConfig;
        collection.random = random;
        I8BallCue(cue).addCollection(collectionId, name);
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

    function _randDesignId(uint256[] memory designIds) internal view returns (uint256) {
        // Not ideal, but about as good as it is going to get without external randomness
        uint256 randBlocksBack = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.number))) % 256;
        uint256 rand = uint256(keccak256(bytes.concat(blockhash(block.number - randBlocksBack))));

        return designIds[rand % designIds.length];
    }

    function _beforeMint(uint256 collectionId) internal view {
        // checks
        require(_collectionIds.contains(collectionId), "8BallCueMinter::Non-existent collectionId");
        require(
            block.timestamp >= _collections[collectionId].mintConfig.startTime || _hasAdminRole(msg.sender),
            "8BallCueMinter::Mint has not started"
        );
        require(_collections[collectionId].designIds.length() > 0, "8BallCueMinter::Sold out");
    }

    function _afterMint(uint256 collectionId, uint256 designId, uint256 payment) internal {
        Collection storage collection = _collections[collectionId];
        DesignBase storage design = collection.designs[designId];
        design.remaining--;
        if (design.remaining == 0) {
            collection.designIds.remove(designId);
        }

        // save and increment the tokenId counter
        uint256 tokenId = _counter.current();
        _counter.increment();

        // mint cue;
        I8BallCue(cue).mint(msg.sender, tokenId, Cue(design.rarity, collectionId, designId, 1, 1, 1, 1));

        emit CuePurchased(msg.sender, tokenId, collectionId, design.rarity, payment);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(AccessControlEnumerableUpgradeable) returns (bool){
        return type(I8BallCueMinter).interfaceId == interfaceId || super.supportsInterface(interfaceId);
    }
}