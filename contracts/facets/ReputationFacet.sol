// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { LibDiamond } from "../diamond/libraries/LibDiamond.sol";
import { LibIdentityStorage } from "../libraries/LibIdentityStorage.sol";

library LibReputationStorage {
    bytes32 constant STORAGE_POSITION = keccak256("afa.identity.reputation.storage.v1");
    struct Layout {
        mapping(uint256 => uint256) reputationScore;
        mapping(uint256 => uint256[]) badges;
        // Endorsements: Endorser -> Endorsed -> Skill -> bool
        mapping(uint256 => mapping(uint256 => mapping(bytes32 => bool))) hasEndorsed;
        // Skill count: TokenID -> SkillHash -> Count
        mapping(uint256 => mapping(bytes32 => uint256)) skillEndorsements;
    }
    function layout() internal pure returns (Layout storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly { s.slot := position }
    }
}

contract ReputationFacet {
    event ReputationChanged(uint256 indexed tokenId, int256 change, uint256 newScore);
    event BadgeAwarded(uint256 indexed tokenId, uint256 badgeId);
    event EndorsementReceived(uint256 indexed from, uint256 indexed to, string skill);

    modifier onlyAdmin() {
        LibDiamond.enforceIsOwner();
        _;
    }

    modifier onlyIdentityOwner() {
        require(LibIdentityStorage.layout()._addressToTokenId[msg.sender] != 0, "No Identity");
        _;
    }

    // --- Admin Functions ---

    function updateReputation(uint256 _tokenId, int256 _change) external onlyAdmin {
        LibReputationStorage.Layout storage rs = LibReputationStorage.layout();
        uint256 currentScore = rs.reputationScore[_tokenId];
        uint256 newScore;

        if (_change < 0) {
            uint256 deduc = uint256(-_change);
            newScore = (currentScore > deduc) ? currentScore - deduc : 0;
        } else {
            newScore = currentScore + uint256(_change);
        }

        rs.reputationScore[_tokenId] = newScore;
        emit ReputationChanged(_tokenId, _change, newScore);
    }

    function awardBadge(uint256 _tokenId, uint256 _badgeId) external onlyAdmin {
        LibReputationStorage.layout().badges[_tokenId].push(_badgeId);
        emit BadgeAwarded(_tokenId, _badgeId);
    }

    // --- Peer-to-Peer Endorsements ---

    function endorseUser(uint256 _targetTokenId, string calldata _skill) external onlyIdentityOwner {
        LibIdentityStorage.Layout storage ids = LibIdentityStorage.layout();
        LibReputationStorage.Layout storage rs = LibReputationStorage.layout();
        
        uint256 myTokenId = ids._addressToTokenId[msg.sender];
        require(myTokenId != _targetTokenId, "Cannot endorse self");
        
        bytes32 skillHash = keccak256(abi.encodePacked(_skill));
        require(!rs.hasEndorsed[myTokenId][_targetTokenId][skillHash], "Already endorsed for this skill");

        rs.hasEndorsed[myTokenId][_targetTokenId][skillHash] = true;
        rs.skillEndorsements[_targetTokenId][skillHash]++;
        
        // Menambah reputasi kecil otomatis (misal +1)
        rs.reputationScore[_targetTokenId]++;
        
        emit EndorsementReceived(myTokenId, _targetTokenId, _skill);
        emit ReputationChanged(_targetTokenId, 1, rs.reputationScore[_targetTokenId]);
    }

    // --- View Functions ---

    function getReputation(uint256 _tokenId) external view returns (uint256) {
        return LibReputationStorage.layout().reputationScore[_tokenId];
    }

    function getBadges(uint256 _tokenId) external view returns (uint256[] memory) {
        return LibReputationStorage.layout().badges[_tokenId];
    }
    
    function getSkillEndorsements(uint256 _tokenId, string calldata _skill) external view returns (uint256) {
        return LibReputationStorage.layout().skillEndorsements[_tokenId][keccak256(abi.encodePacked(_skill))];
    }
}
