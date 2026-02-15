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
    
    // Core Events
    event AttestationIssued(uint256 indexed targetTokenId, address indexed issuer, string key, bytes value);
    event AttestationRevoked(uint256 indexed targetTokenId, address indexed revoker, string key, uint256 attestationIndex);
    event AttestationUpdated(uint256 indexed targetTokenId, address indexed updater, string key, bytes oldValue, bytes newValue);
    
    // Premium Events
    event PremiumActivated(uint256 indexed tokenId, address indexed activator, uint256 expiration);
    event PremiumExtended(uint256 indexed tokenId, address indexed extender, uint256 oldExpiration, uint256 newExpiration);
    event PremiumExpired(uint256 indexed tokenId, uint256 expiredAt);
    event PremiumTransferred(uint256 indexed fromTokenId, uint256 indexed toTokenId, address indexed transferer);
    
    // Admin Events
    event AttestationBatchIssued(uint256[] indexed tokenIds, address indexed issuer, string key, bytes value, uint256 count);
    event AttestationKeyRemoved(uint256 indexed tokenId, address indexed remover, string key);
    event AttestationsCleared(uint256 indexed tokenId, address indexed clearer, uint256 count);
    
    // Security Events
    event UnauthorizedAccessAttempt(address indexed caller, string method, bytes data);
    event AttestationVerificationFailed(uint256 indexed tokenId, string key, string reason);
    
    // System Events
    event StorageMigrated(uint256 indexed tokenId, uint256 attestationCount);
    event SchemaUpdated(string indexed key, string oldSchema, string newSchema);

    modifier onlyAdmin() {
        LibDiamond.enforceIsOwner();
        _;
    }

    modifier onlyValidToken(uint256 tokenId) {
        require(tokenId > 0, "Invalid token ID");
        _;
    }

    modifier attestationExists(uint256 tokenId, uint256 index) {
        require(index < LibAttestationStorage.layout().userAttestations[tokenId].length, "Attestation not found");
        _;
    }

    // --- Write Functions ---

    /// @notice Admin menerbitkan atestasi (sertifikat) ke user
    function issueAttestation(uint256 _targetTokenId, string calldata _key, bytes calldata _value) 
        external 
        onlyAdmin 
        onlyValidToken(_targetTokenId) 
    {
        LibAttestationStorage.Layout storage as_ = LibAttestationStorage.layout();
        
        as_.userAttestations[_targetTokenId].push(LibAttestationStorage.Attestation({
            issuerId: 0, // 0 = System/Admin
            timestamp: uint64(block.timestamp),
            key: _key,
            value: _value
        }));

        emit AttestationIssued(_targetTokenId, msg.sender, _key, _value);
    }

    /// @notice Batch issue attestations to multiple users
    function batchIssueAttestations(uint256[] calldata _targetTokenIds, string calldata _key, bytes calldata _value) 
        external 
        onlyAdmin 
    {
        require(_targetTokenIds.length > 0, "Empty array");
        
        LibAttestationStorage.Layout storage as_ = LibAttestationStorage.layout();
        
        for (uint i = 0; i < _targetTokenIds.length; i++) {
            require(_targetTokenIds[i] > 0, "Invalid token ID");
            
            as_.userAttestations[_targetTokenIds[i]].push(LibAttestationStorage.Attestation({
                issuerId: 0,
                timestamp: uint64(block.timestamp),
                key: _key,
                value: _value
            }));
        }

        emit AttestationBatchIssued(_targetTokenIds, msg.sender, _key, _value, _targetTokenIds.length);
    }

    /// @notice Revoke a specific attestation
    function revokeAttestation(uint256 _targetTokenId, uint256 _attestationIndex) 
        external 
        onlyAdmin 
        onlyValidToken(_targetTokenId) 
        attestationExists(_targetTokenId, _attestationIndex)
    {
        LibAttestationStorage.Layout storage as_ = LibAttestationStorage.layout();
        LibAttestationStorage.Attestation storage att = as_.userAttestations[_targetTokenId][_attestationIndex];
        
        string memory key = att.key;
        
        // Remove by swapping with last element and popping
        uint256 lastIndex = as_.userAttestations[_targetTokenId].length - 1;
        if (_attestationIndex != lastIndex) {
            as_.userAttestations[_targetTokenId][_attestationIndex] = as_.userAttestations[_targetTokenId][lastIndex];
        }
        as_.userAttestations[_targetTokenId].pop();

        emit AttestationRevoked(_targetTokenId, msg.sender, key, _attestationIndex);
    }

    /// @notice Update an existing attestation
    function updateAttestation(uint256 _targetTokenId, uint256 _attestationIndex, bytes calldata _newValue) 
        external 
        onlyAdmin 
        onlyValidToken(_targetTokenId) 
        attestationExists(_targetTokenId, _attestationIndex)
    {
        LibAttestationStorage.Layout storage as_ = LibAttestationStorage.layout();
        LibAttestationStorage.Attestation storage att = as_.userAttestations[_targetTokenId][_attestationIndex];
        
        bytes memory oldValue = att.value;
        att.value = _newValue;
        att.timestamp = uint64(block.timestamp);

        emit AttestationUpdated(_targetTokenId, msg.sender, att.key, oldValue, _newValue);
    }

    /// @notice Remove all attestations with a specific key for a token
    function removeAttestationsByKey(uint256 _targetTokenId, string calldata _key) 
        external 
        onlyAdmin 
        onlyValidToken(_targetTokenId) 
    {
        LibAttestationStorage.Layout storage as_ = LibAttestationStorage.layout();
        LibAttestationStorage.Attestation[] storage attestations = as_.userAttestations[_targetTokenId];
        
        uint256 removedCount = 0;
        for (uint256 i = 0; i < attestations.length; ) {
            if (keccak256(bytes(attestations[i].key)) == keccak256(bytes(_key))) {
                // Remove by swapping with last element
                attestations[i] = attestations[attestations.length - 1];
                attestations.pop();
                removedCount++;
            } else {
                i++;
            }
        }

        emit AttestationKeyRemoved(_targetTokenId, msg.sender, _key);
    }

    // --- Premium Logic (Enhanced) ---

    function isPremium(uint256 tokenId) public view returns (bool) {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        return s.premiumExpirations[tokenId] > block.timestamp;
    }

    function getPremiumExpiration(uint256 tokenId) public view returns (uint256) {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        return s.premiumExpirations[tokenId];
    }

    /// @notice Activate premium for a token
    function activatePremium(uint256 tokenId, uint256 duration) external onlyAdmin onlyValidToken(tokenId) {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        uint256 expiration = block.timestamp + duration;
        s.premiumExpirations[tokenId] = expiration;
        
        emit PremiumActivated(tokenId, msg.sender, expiration);
    }

    /// @notice Extend premium for a token
    function extendPremium(uint256 tokenId, uint256 additionalDuration) external onlyAdmin onlyValidToken(tokenId) {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        uint256 oldExpiration = s.premiumExpirations[tokenId];
        uint256 newExpiration = oldExpiration + additionalDuration;
        s.premiumExpirations[tokenId] = newExpiration;
        
        emit PremiumExtended(tokenId, msg.sender, oldExpiration, newExpiration);
    }

    /// @notice Check and emit expired premiums
    function checkPremiumExpired(uint256 tokenId) external onlyValidToken(tokenId) {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        if (s.premiumExpirations[tokenId] <= block.timestamp && s.premiumExpirations[tokenId] != 0) {
            emit PremiumExpired(tokenId, s.premiumExpirations[tokenId]);
        }
    }

    /// @notice Transfer premium from one token to another
    function transferPremium(uint256 fromTokenId, uint256 toTokenId) external onlyAdmin {
        require(fromTokenId > 0 && toTokenId > 0, "Invalid token IDs");
        require(fromTokenId != toTokenId, "Cannot transfer to same token");
        
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        uint256 expiration = s.premiumExpirations[fromTokenId];
        require(expiration > block.timestamp, "No active premium");
        
        s.premiumExpirations[toTokenId] = expiration;
        delete s.premiumExpirations[fromTokenId];
        
        emit PremiumTransferred(fromTokenId, toTokenId, msg.sender);
    }

    // --- View Functions (Enhanced) ---

    function getAttestations(uint256 _tokenId) external view returns (LibAttestationStorage.Attestation[] memory) {
        return LibAttestationStorage.layout().userAttestations[_tokenId];
    }

    function getAttestationsByKey(uint256 _tokenId, string calldata _key) 
        external 
        view 
        returns (LibAttestationStorage.Attestation[] memory) 
    {
        LibAttestationStorage.Attestation[] storage allAttestations = LibAttestationStorage.layout().userAttestations[_tokenId];
        
        // Count matching attestations
        uint256 count = 0;
        for (uint256 i = 0; i < allAttestations.length; i++) {
            if (keccak256(bytes(allAttestations[i].key)) == keccak256(bytes(_key))) {
                count++;
            }
        }
        
        // Build result array
        LibAttestationStorage.Attestation[] memory result = new LibAttestationStorage.Attestation[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < allAttestations.length; i++) {
            if (keccak256(bytes(allAttestations[i].key)) == keccak256(bytes(_key))) {
                result[index] = allAttestations[i];
                index++;
            }
        }
        
        return result;
    }

    function getAttestationCount(uint256 _tokenId) external view returns (uint256) {
        return LibAttestationStorage.layout().userAttestations[_tokenId].length;
    }

    function hasAttestation(uint256 _tokenId, string calldata _key) external view returns (bool) {
        LibAttestationStorage.Attestation[] storage attestations = LibAttestationStorage.layout().userAttestations[_tokenId];
        
        for (uint256 i = 0; i < attestations.length; i++) {
            if (keccak256(bytes(attestations[i].key)) == keccak256(bytes(_key))) {
                return true;
            }
        }
        return false;
    }

    function getLatestAttestation(uint256 _tokenId, string calldata _key) external view returns (LibAttestationStorage.Attestation memory) {
        LibAttestationStorage.Attestation[] storage attestations = LibAttestationStorage.layout().userAttestations[_tokenId];
        
        LibAttestationStorage.Attestation memory latest;
        uint64 latestTimestamp = 0;
        
        for (uint256 i = 0; i < attestations.length; i++) {
            if (keccak256(bytes(attestations[i].key)) == keccak256(bytes(_key)) && attestations[i].timestamp > latestTimestamp) {
                latest = attestations[i];
                latestTimestamp = attestations[i].timestamp;
            }
        }
        
        require(latestTimestamp > 0, "No attestation found");
        return latest;
    }

    // --- Admin Functions ---

    /// @notice Clear all attestations for a token (use with caution)
    function clearAttestations(uint256 _tokenId) external onlyAdmin onlyValidToken(_tokenId) {
        uint256 count = LibAttestationStorage.layout().userAttestations[_tokenId].length;
        delete LibAttestationStorage.layout().userAttestations[_tokenId];
        
        emit AttestationsCleared(_tokenId, msg.sender, count);
    }

    /// @notice Migrate attestations from old storage (if needed)
    function migrateAttestations(uint256 _tokenId, LibAttestationStorage.Attestation[] calldata _attestations) 
        external 
        onlyAdmin 
        onlyValidToken(_tokenId) 
    {
        LibAttestationStorage.Layout storage as_ = LibAttestationStorage.layout();
        
        for (uint256 i = 0; i < _attestations.length; i++) {
            as_.userAttestations[_tokenId].push(_attestations[i]);
        }
        
        emit StorageMigrated(_tokenId, _attestations.length);
    }
}
