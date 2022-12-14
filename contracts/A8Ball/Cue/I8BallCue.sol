// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import "../I8BallCommon.sol";

/**
* @title Arcadian 8Ball Cue Interface v1.0.0
* @author @DirtyCajunRice
*/
interface I8BallCue is IERC721Upgradeable, I8BallCommon {
    function mint(address to, uint256 tokenId, Cue calldata cue) external;
    function upgradeCue(address owner, uint256 tokenId, Cue calldata cue) external;
    function maxLevel(Rarity rarity) external pure returns (uint256);
    function addCollection(uint256 collectionId, string memory name) external;
    function addCollectionDesigns(uint256 collectionId, Design[] memory designs) external;

    function setImageBaseUri(string memory _imageBaseURI) external;
    function getCue(uint256 tokenId) external view returns (Cue memory);
}