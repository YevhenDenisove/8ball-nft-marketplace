// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

/**
* @title Arcadian 8Ball Common Interface v1.0.0
* @author @DirtyCajunRice
*/
interface I8BallCommon {
    enum Rarity { Common, Uncommon, Rare, Epic, Legendary }

    struct Design {
        Rarity rarity;
        uint256 id;
        uint256 remaining;
        string name;
    }

    struct Cue {
        Rarity rarity;
        uint256 collectionId;
        uint256 designId;
        uint256 power;
        uint256 accuracy;
        uint256 spin;
        uint256 time;
    }
}