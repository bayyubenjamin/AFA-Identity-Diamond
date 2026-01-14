// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library LibIdentityStorage {
    bytes32 constant STORAGE_POSITION = keccak256("afa.identity.storage.v1");

    struct Layout {
        address verifierAddress;
        string baseURI;
        
        // Mappings standard ERC721
        mapping(uint256 => address) _tokenIdToAddress;
        mapping(address => uint256) _addressToTokenId;
        mapping(address => uint256) _balances;
        
        // Security & Logic
        mapping(address => uint256) nonce;
        
        // [NEW] Subscription & Financial Data
        mapping(uint256 => uint256) premiumExpirations; // tokenId -> timestamp
        mapping(uint256 => uint256) subscriptionPrices;  // tierId -> priceInWei
        
        address treasuryAddress;      // Alamat penerima dana
        uint256 reentrancyStatus;     // Mutex untuk keamanan (1: Unlocked, 2: Locked)
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
}
