// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import "@dirtycajunrice/contracts/token/ERC721/extensions/ERC721EnumerableV2.sol";
import "@dirtycajunrice/contracts/token/ERC721/extensions/ERC721URITokenJSON.sol";
import "@dirtycajunrice/contracts/token/ERC721/extensions/ERC721BurnableV2.sol";
import "@dirtycajunrice/contracts/token/ERC721/extensions/ERC721Capped.sol";
import "@dirtycajunrice/contracts/utils/access/StandardAccessControl.sol";
import "@dirtycajunrice/contracts/utils/structs/Attributes.sol";
import "@dirtycajunrice/contracts/utils/TokenMetadata.sol";

import "../I8BallCommon.sol";
import "./I8BallCue.sol";

/**
* @title Arcadian 8Ball Cue v1.0.0
* @author @DirtyCajunRice
*/
contract A8BallCue is Initializable, I8BallCue, ERC721EnumerableV2, ERC721BurnableV2, ERC721URITokenJSON,
StandardAccessControl, PausableUpgradeable, UUPSUpgradeable {
    using StringsUpgradeable for uint256;
    using Attributes for Attributes.AttributeStore;

    Attributes.AttributeStore private _attributes;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ERC721_init("8BallCue", "8BALLCUE");
        __ERC721EnumerableV2_init();
        __ERC721URITokenJSON_init("https://images.arcadian.game/8BallCue/");
        __Pausable_init();
        __StandardAccessControl_init();
        __ERC721BurnableV2_init();
        __UUPSUpgradeable_init();

        // core metadata
        _attributes.addTree(0, "Core Metadata");
        _attributes.addSkill(0, 0, "Collection");
    }

    function mint(address to, uint256 tokenId, Cue calldata cue) external onlyContract {
        _safeMint(to, tokenId);
        
        _attributes.setValue(tokenId, 0, 0, cue.collectionId);
        _attributes.setValue(tokenId, cue.collectionId, 0, block.timestamp);
        _attributes.setValue(tokenId, cue.collectionId, 1, uint256(cue.rarity));
        _attributes.setValue(tokenId, cue.collectionId, 2, cue.designId);
        _attributes.setValue(tokenId, cue.collectionId, 3, cue.power);
        _attributes.setValue(tokenId, cue.collectionId, 4, cue.accuracy);
        _attributes.setValue(tokenId, cue.collectionId, 5, cue.spin);
        _attributes.setValue(tokenId, cue.collectionId, 6, cue.time);
        
    }

    function upgradeCue(address owner, uint256 tokenId, Cue calldata cue) external onlyContract {
        require(_isApprovedOrOwner(owner, tokenId), "8BallCue::Not approved or owner");

        uint256 collectionId = _attributes.getValue(tokenId, 0, 0);
        uint256 rarity = _attributes.getValue(tokenId, collectionId, 1);
        uint256 max = rarity == 0 ? 5 : 6 + rarity ;

        for (uint256 i = 3; i < 7; i++) {
            require(_attributes.getValue(tokenId, collectionId, i) < max, "8BallCue::Upgrade exceeds max level");
        }

        _attributes.setValue(tokenId, collectionId, 3, cue.power);
        _attributes.setValue(tokenId, collectionId, 4, cue.accuracy);
        _attributes.setValue(tokenId, collectionId, 5, cue.spin);
        _attributes.setValue(tokenId, collectionId, 6, cue.time);
    }

    function maxLevel(Rarity rarity) public pure returns (uint256) {
        return rarity == Rarity.Common ? 5 : 6 + uint256(rarity);
    }

    function getCue(uint256 tokenId) public view returns (Cue memory) {
        uint256 collectionId = _attributes.getValue(tokenId, 0, 0);
        require(collectionId > 0, "8BallCue::Invalid Token ID");
        return Cue({
            rarity: Rarity(_attributes.getValue(tokenId, collectionId, 1)),
            collectionId: collectionId,
            designId: _attributes.getValue(tokenId, collectionId, 2),
            power: _attributes.getValue(tokenId, collectionId, 3),
            accuracy: _attributes.getValue(tokenId, collectionId, 4),
            spin: _attributes.getValue(tokenId, collectionId, 5),
            time: _attributes.getValue(tokenId, collectionId, 6)
        });
    }

    function tokenURIJSON(uint256 tokenId) public view override(ERC721URITokenJSON) returns(string memory) {
        uint256 collectionId = _attributes.getValue(tokenId, 0, 0);

        TokenMetadata.Attribute[] memory attributes = new TokenMetadata.Attribute[](7);

        attributes[0] = TokenMetadata.Attribute(
            _attributes.getSkillName(0, 0),
            '',
            _attributes.getTreeName(collectionId),
            false
        );
        attributes[1] = TokenMetadata.Attribute(
            _attributes.getSkillName(collectionId, 0),
            'date',
            _attributes.getValue(tokenId, collectionId, 0).toString(),
            true
        );
        attributes[2] = TokenMetadata.Attribute(
            _attributes.getSkillName(collectionId, 1),
            '',
            ["Common", "Uncommon", "Rare", "Epic", "Legendary"][_attributes.getValue(tokenId, collectionId, 1)],
            false
        );

        for (uint256 i = 3; i < 7; i++) {
            attributes[i] = TokenMetadata.Attribute(
                _attributes.getSkillName(collectionId, i),
                'number',
                _attributes.getValue(tokenId, collectionId, i).toString(),
                true
            );
        }

        return makeMetadataJSON(
            tokenId,
            _attributes.getName(collectionId, 2, _attributes.getValue(tokenId, collectionId, 2)),
            'Crypto 8Ball Cue',
            attributes
        );
    }

    ///
    /// Contract
    ///
    function addCollection(uint256 collectionId, string memory name) external onlyContract {
        // treeId 0 is reserved for core metadata
        require(collectionId > 0, "8BallCue::Invalid collectionId");

        _attributes.addTree(collectionId, name);
        _attributes.addSkill(collectionId, 0, "Birthday");
        _attributes.addSkill(collectionId, 1, "Rarity");
        _attributes.addSkill(collectionId, 2, "Design");
        _attributes.addSkill(collectionId, 3, "Power");
        _attributes.addSkill(collectionId, 4, "Accuracy");
        _attributes.addSkill(collectionId, 5, "Spin");
        _attributes.addSkill(collectionId, 6, "Time");
    }

    function addCollectionDesigns(uint256 collectionId, Design[] memory designs) external onlyContract {
        for (uint256 i = 0; i < designs.length; i++) {
            _attributes.setName(collectionId, 2, designs[i].id, designs[i].name);
        }
    }
    ///
    /// Admin
    ///
    function setImageBaseUri(string memory _imageBaseURI) external onlyAdmin {
        imageBaseURI = _imageBaseURI;
    }

    ///
    /// Overrides
    ///
    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override(ERC721URITokenJSON, ERC721Upgradeable)
    returns(string memory) {
        return ERC721URITokenJSON.tokenURI(tokenId);
    }

    function imageURISuffix(
        uint256 tokenId
    ) internal view virtual override(ERC721URITokenJSON) returns (string memory) {
        uint256 collectionId = _attributes.getValue(tokenId, 0, 0);
        return string(
            abi.encodePacked(_attributes.getTreeName(collectionId), "/", _attributes.getValue(tokenId, collectionId, 2).toString())
        );
    }

    function _safeMint(address to, uint256 tokenId) internal virtual override(ERC721Upgradeable) {
        super._safeMint(to, tokenId);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyAdmin {}

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(AccessControlEnumerableUpgradeable, ERC721EnumerableV2, ERC721Upgradeable, IERC165Upgradeable)
    returns (bool)
    {
        return type(I8BallCue).interfaceId == interfaceId || super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override(ERC721EnumerableV2, ERC721Upgradeable) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

}
