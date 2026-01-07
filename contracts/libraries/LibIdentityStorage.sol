// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library LibIdentityStorage {
    // --- Enums ---
    enum SubscriptionTier {
        ONE_MONTH,
        SIX_MONTHS,
        ONE_YEAR
    }

    // --- Custom Errors (Gas Efficient) ---
    error MintToZeroAddress();
    error AddressAlreadyHasIdentity();

    // --- Storage Layout ---
    struct Layout {
        // Core Identity Mappings (1-to-1 relationship)
        mapping(address => uint256) _addressToTokenId; // Reverse lookup for easy identity check
        mapping(uint256 => address) _tokenIdToAddress; // Primary owner lookup
        
        // Configuration
        address verifierAddress;
        string baseURI;
        mapping(address => uint256) nonce;
        
        // Subscription System
        mapping(uint256 => uint256) premiumExpirations; // tokenId => timestamp
        mapping(SubscriptionTier => uint256) pricePerTierInWei;

        // ERC721 Standard & Enumerable Data
        mapping(uint256 => address) _owners;          // tokenId => owner (Redundant with _tokenIdToAddress but kept for ERC721 std compliance)
        mapping(address => uint256) _balances;        // owner => token count
        mapping(address => mapping(uint256 => uint256)) _ownedTokens; // owner => index => tokenId
        mapping(uint256 => uint256) _ownedTokensIndex; // tokenId => index in owner's list
        
        uint256[] _allTokens;                         // Array of all tokenIds
        mapping(uint256 => uint256) _allTokensIndex;  // tokenId => global index
        
        uint256 _tokenIdTracker;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("identity.storage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    // --- Internal Logic ---

    function _mint(Layout storage s, address to) internal returns (uint256 tokenId) {
        if (to == address(0)) revert MintToZeroAddress();
        
        // Enforce 1-Identity-Per-Address Rule
        if (s._addressToTokenId[to] != 0) revert AddressAlreadyHasIdentity();

        // Generate ID
        tokenId = ++s._tokenIdTracker;

        // 1. Update Core Identity Mappings
        s._tokenIdToAddress[tokenId] = to;
        s._addressToTokenId[to] = tokenId;
        s._owners[tokenId] = to;

        // 2. Update ERC721 Enumerable (Owner List)
        uint256 length = s._balances[to];
        s._ownedTokens[to][length] = tokenId;
        s._ownedTokensIndex[tokenId] = length;
        s._balances[to] += 1;

        // 3. Update ERC721 Enumerable (Global List)
        s._allTokensIndex[tokenId] = s._allTokens.length;
        s._allTokens.push(tokenId);
        
        // Note: Event 'Transfer' (Mint) harus di-emit oleh Facet pemanggil
        // agar sesuai dengan ABI Facet tersebut.
    }
}
