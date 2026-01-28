// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../libraries/LibIdentityStorage.sol";
import { LibDiamond } from "../diamond/libraries/LibDiamond.sol";

library LibAttestationStorage {
    bytes32 constant STORAGE_POSITION = keccak256("afa.identity.attestation.storage.v1");
    struct Attestation {
        uint256 issuerId; // TokenID penerbit (0 jika admin/system)
        uint64 timestamp;
        string key;       // Misal: "KYC_LEVEL"
        bytes value;      // Misal: "2" atau "Verified"
    }
    struct Layout {
        // TokenID -> Attestations
        mapping(uint256 => Attestation[]) userAttestations;
    }
    function layout() internal pure returns (Layout storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly { s.slot := position }
    }
}

contract AttestationFacet {
    
    event AttestationIssued(uint256 indexed targetTokenId, address indexed issuer, string key, bytes value);

    modifier onlyAdmin() {
        LibDiamond.enforceIsOwner();
        _;
    }

    // --- Write Functions ---

    /// @notice Admin menerbitkan atestasi (sertifikat) ke user
    function issueAttestation(uint256 _targetTokenId, string calldata _key, bytes calldata _value) external onlyAdmin {
        LibAttestationStorage.Layout storage as_ = LibAttestationStorage.layout();
        
        as_.userAttestations[_targetTokenId].push(LibAttestationStorage.Attestation({
            issuerId: 0, // 0 = System/Admin
            timestamp: uint64(block.timestamp),
            key: _key,
            value: _value
        }));

        emit AttestationIssued(_targetTokenId, msg.sender, _key, _value);
    }

    // --- Original Premium Logic (Preserved) ---

    function isPremium(uint256 tokenId) public view returns (bool) {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        return s.premiumExpirations[tokenId] > block.timestamp;
    }

    function getPremiumExpiration(uint256 tokenId) public view returns (uint256) {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        return s.premiumExpirations[tokenId];
    }

    // --- New View Functions ---

    function getAttestations(uint256 _tokenId) external view returns (LibAttestationStorage.Attestation[] memory) {
        return LibAttestationStorage.layout().userAttestations[_tokenId];
    }
}
