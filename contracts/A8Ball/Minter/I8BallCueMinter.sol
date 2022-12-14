// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import "../I8BallCommon.sol";

/**
* @title Arcadian 8Ball Cue Minter Interface v1.0.0
* @author @DirtyCajunRice
*/
interface I8BallCueMinter is I8BallCommon {

    /***********
     * Structs *
     ***********/

    struct AllowlistConfig {
        uint256 duration;
        uint256 discount;
    }

    struct RoyaltyConfig {
        address treasury;
        uint256 basisPoints;
    }

    struct DesignBase {
        Rarity rarity;
        uint256 remaining;
    }

    struct MintConfig {
        uint256 startTime;
        uint256 price;
    }

    struct Collection {
        MintConfig mintConfig;
        AllowlistConfig allowlistConfig;
        EnumerableSetUpgradeable.AddressSet allowlist;
        RoyaltyConfig royaltyConfig;
        // designId => design;
        EnumerableSetUpgradeable.UintSet designIds;
        mapping(uint256 => DesignBase) designs;
    }

    /**********
     * Events *
     **********/

    event CuePurchased(address indexed from, uint256 tokenId, uint256 collectionId, Rarity rarity, uint256 price);
    event CueUpgraded(address indexed from, uint256 tokenId, uint256 collectionId, Rarity rarity, uint256 price);
    event RoyaltyPaid(address indexed from, address indexed to, uint256 collectionId, uint256 amount);
    event RoyaltyShareFailed(address indexed from, address indexed to, uint256 collectionId, uint256 amount);

    /*************
     * Variables *
     *************/

    // Treasury address
    function treasury() external view returns(address);
    // 8BallCue address
    function cue() external view returns(address);


    /*************
     * Functions *
     *************/

    function mintCue(uint256 collectionId) external payable;

    function addCollection(
        uint256 collectionId,
        string calldata name,
        MintConfig calldata mintConfig,
        AllowlistConfig calldata allowlistConfig
    ) external;

    function addCollectionDesigns(uint256 collectionId, Design[] calldata designs) external;

    function setCollectionRoyaltyConfig(uint256 collectionId, RoyaltyConfig calldata config) external;
    function setCollectionMintConfig(uint256 collectionId, MintConfig calldata config) external;
    function setCollectionAllowlistConfig(uint256 collectionId, AllowlistConfig calldata config) external;
    function addToCollectionAllowlist(uint256 collectionId, address[] calldata wallets) external;
    function removeFromCollectionAllowlist(uint256 collectionId, address[] calldata wallets) external;
    function getCollectionIds() external view returns (uint256[] memory);
    function getCollectionRoyaltyConfig(uint256 collectionId) external view returns (RoyaltyConfig memory);
    function getCollectionMintConfig(uint256 collectionId) external view returns (MintConfig memory);
    function getCollectionAllowlistConfig(uint256 collectionId) external view returns (AllowlistConfig memory);
    function getCollectionAllowlist(uint256 collectionId) external view returns (address[] memory);
    function isAllowlisted(uint256 collectionId, address wallet) external view returns (bool);
}