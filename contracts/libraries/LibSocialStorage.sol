// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library LibSocialStorage {
    bytes32 constant STORAGE_POSITION = keccak256("afa.identity.social.storage.v1");

    struct Profile {
        string handle;        // Username unik (ex: "satoshi")
        string displayName;   // Nama Tampilan (ex: "Satoshi Nakamoto")
        string bio;           // Deskripsi singkat
        string avatarURI;     // Link gambar (IPFS/URL)
        string externalLink;  // Link website/twitter
        uint256 reputationScore; // Skor reputasi
        bool isPublic;        // Status privasi
        bool initialized;     // Penanda apakah profil sudah diset
    }

    struct Layout {
        // TokenID => Profile Data
        mapping(uint256 => Profile) profiles;
        
        // Handle => TokenID (Untuk cek keunikan handle)
        mapping(string => uint256) handleToTokenId;
        
        // Config: Karakter minimum/maksimum handle
        uint256 minHandleLength;
        uint256 maxHandleLength;
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
}
