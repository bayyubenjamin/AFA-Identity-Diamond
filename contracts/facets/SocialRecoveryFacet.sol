// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../libraries/LibIdentityStorage.sol";
import "../libraries/LibRecoveryStorage.sol"; // Pastikan library ini ada/dibuat
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// Kita definisikan Library internal jika file LibRecoveryStorage.sol belum ada atau ingin di-override
library LibRecoveryInternal {
    bytes32 constant STORAGE_POSITION = keccak256("afa.identity.recovery.storage.v1");
    struct Layout {
        // TokenID -> List Guardian Addresses
        mapping(uint256 => address[]) guardians;
        // TokenID -> Threshold (min vote)
        mapping(uint256 => uint256) threshold;
        // TokenID -> Recovery Round (nonce untuk replay protection)
        mapping(uint256 => uint256) recoveryNonce;
    }
    function layout() internal pure returns (Layout storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly { s.slot := position }
    }
}

contract SocialRecoveryFacet {
    using ECDSA for bytes32;

    event GuardiansUpdated(uint256 indexed tokenId, address[] newGuardians, uint256 threshold);
    event RecoveryExecuted(uint256 indexed tokenId, address oldOwner, address newOwner);

    error Recovery_Unauthorized();
    error Recovery_InvalidThreshold();
    error Recovery_DuplicateGuardian();
    error Recovery_NotEnoughSignatures();
    error Recovery_InvalidSignature();

    // --- Configuration ---

    /// @notice User mengatur Guardian mereka (misal: 3 teman, threshold 2)
    function setGuardians(address[] calldata _guardians, uint256 _threshold) external {
        LibIdentityStorage.Layout storage ids = LibIdentityStorage.layout();
        uint256 tokenId = ids._addressToTokenId[msg.sender];
        require(tokenId != 0, "Identity not found");

        if (_threshold == 0 || _threshold > _guardians.length) revert Recovery_InvalidThreshold();

        LibRecoveryInternal.Layout storage rs = LibRecoveryInternal.layout();
        
        // Reset guardians
        rs.guardians[tokenId] = _guardians;
        rs.threshold[tokenId] = _threshold;

        emit GuardiansUpdated(tokenId, _guardians, _threshold);
    }

    // --- Recovery Execution ---

    /// @notice Eksekusi pemulihan akun dengan tanda tangan para Guardian
    /// @param _tokenId ID yang mau dipulihkan
    /// @param _newOwner Address wallet baru
    /// @param _signatures Array tanda tangan dari para guardian
    function recoverIdentity(
        uint256 _tokenId, 
        address _newOwner, 
        bytes[] calldata _signatures
    ) external {
        LibRecoveryInternal.Layout storage rs = LibRecoveryInternal.layout();
        LibIdentityStorage.Layout storage ids = LibIdentityStorage.layout();

        uint256 threshold = rs.threshold[_tokenId];
        require(threshold > 0, "Recovery not configured");
        require(_signatures.length >= threshold, "Not enough signatures");
        require(ids._addressToTokenId[_newOwner] == 0, "New owner already has identity");

        // Hash data yang disign oleh guardian: keccak256(tokenId, newOwner, nonce, contractAddress)
        bytes32 hash = keccak256(abi.encodePacked(
            _tokenId, 
            _newOwner, 
            rs.recoveryNonce[_tokenId],
            address(this)
        ));
        bytes32 ethSignedHash = hash.toEthSignedMessageHash();

        // Verifikasi Signature
        uint256 validSignatures = 0;
        address[] memory guardians = rs.guardians[_tokenId];
        address lastSigner = address(0);

        for (uint i = 0; i < _signatures.length; i++) {
            address signer = ethSignedHash.recover(_signatures[i]);
            
            // Pastikan signer adalah guardian yang sah
            bool isGuardian = false;
            for (uint j = 0; j < guardians.length; j++) {
                if (guardians[j] == signer) {
                    isGuardian = true;
                    break;
                }
            }

            // Mencegah duplicate signature dari orang yang sama
            if (isGuardian && signer > lastSigner) {
                validSignatures++;
                lastSigner = signer;
            }
        }

        if (validSignatures < threshold) revert Recovery_NotEnoughSignatures();

        // --- Execute Transfer (Bypassing Soulbound Check) ---
        address oldOwner = ids._tokenIdToAddress[_tokenId];
        
        // 1. Update mapping ownership
        ids._tokenIdToAddress[_tokenId] = _newOwner;
        ids._addressToTokenId[_newOwner] = _tokenId;
        
        // 2. Hapus data owner lama
        delete ids._addressToTokenId[oldOwner];
        ids._balances[oldOwner] -= 1;
        ids._balances[_newOwner] += 1;

        // 3. Update Nonce Recovery
        rs.recoveryNonce[_tokenId]++;

        emit RecoveryExecuted(_tokenId, oldOwner, _newOwner);
    }
    
    // --- View ---
    
    function getGuardians(uint256 _tokenId) external view returns (address[] memory) {
        return LibRecoveryInternal.layout().guardians[_tokenId];
    }
}
