// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library LibIdentityStorage {
    bytes32 public constant STORAGE_POSITION = keccak256("diamond.standard.identity.storage.v1");

    // --- Data Storage Struct ---
    struct Layout {
        // --- ERC721 Core Data ---
        mapping(uint256 => address) _tokenIdToAddress;
        mapping(address => uint256) _addressToTokenId;
        uint256 _totalSupply;
        uint256 _nextTokenId;

        // --- ERC721 Metadata ---
        string baseURI;

        // --- Identity Logic ---
        address verifierAddress;
        mapping(address => uint256) nonce;

        // --- Subscription Logic ---
        uint256 priceInUSD;
        address priceFeed;
        mapping(uint256 => uint256) premiumExpirations;
    }

    // --- Helper Functions ---

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    /// @notice Internal function to mint a new token.
    /// @return tokenId of the minted token
    function _mint(Layout storage s, address _to) internal returns (uint256) {
        require(_to != address(0), "ERC721: mint to the zero address");
        require(s._addressToTokenId[_to] == 0, "ERC721: user already owns a token");

        s._totalSupply++;
        uint256 id = ++s._nextTokenId;
        
        s._tokenIdToAddress[id] = _to;
        s._addressToTokenId[_to] = id;
        return id;
        // Event Transfer akan diemit di facet, BUKAN di sini
    }

    /// @notice Internal function to burn a token.
    function _burn(Layout storage s, uint256 _tokenId) internal returns (address owner) {
        owner = s._tokenIdToAddress[_tokenId];
        require(owner != address(0), "ERC721: burn nonexistent token");

        s._totalSupply--;
        delete s._tokenIdToAddress[_tokenId];
        delete s._addressToTokenId[owner];
        // Event Transfer akan diemit di facet, BUKAN di sini
    }
}
