// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../libraries/LibIdentityStorage.sol";
import "../libraries/LibSocialStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

// --- Re-declare Storage Libraries to Access Data from Other Facets ---
// (Storage Slot MESTI sama persis dengan yang ada di SocialProfileFacet & ReputationFacet)

library LibSocialGraphStorage {
    bytes32 constant STORAGE_POSITION = keccak256("afa.identity.socialgraph.storage.v1");
    struct Layout {
        mapping(uint256 => mapping(uint256 => bool)) isFollowing;
        mapping(uint256 => uint256) followerCount;
        mapping(uint256 => uint256) followingCount;
        // Note: Mapping tidak bisa di-iterate, jadi kita butuh indexer external 
        // atau gunakan Events (The Graph) untuk list lengkap. 
        // Di sini kita sediakan view helpers.
    }
    function layout() internal pure returns (Layout storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly { s.slot := position }
    }
}

library LibReputationStorage {
    bytes32 constant STORAGE_POSITION = keccak256("afa.identity.reputation.storage.v1");
    struct Layout {
        mapping(uint256 => uint256) reputationScore;
        mapping(uint256 => uint256[]) badges; 
    }
    function layout() internal pure returns (Layout storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly { s.slot := position }
    }
}

contract IdentityEnumerableFacet is IERC721Enumerable {
    // --- ERC721Enumerable Implementation ---
    // Karena token kita Soulbound & Sequential Mint (1, 2, 3...), implementasinya efisien.

    function totalSupply() external view override returns (uint256) {
        return LibIdentityStorage.layout().totalSupply;
    }

    function tokenByIndex(uint256 index) external view override returns (uint256) {
        // Karena ID berurutan mulai dari 1
        require(index < LibIdentityStorage.layout().totalSupply, "Index out of bounds");
        return index + 1;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) external view override returns (uint256) {
        require(index == 0, "Owner only has 1 token");
        uint256 tokenId = LibIdentityStorage.layout()._addressToTokenId[owner];
        require(tokenId != 0, "Owner has no token");
        return tokenId;
    }

    // --- Extended View Functions (Frontend Helpers) ---

    struct FullProfile {
        uint256 tokenId;
        string handle;
        string displayName;
        string avatarURI;
        uint256 reputation;
        uint256 followers;
        uint256 following;
        bool isPremium;
    }

    /// @notice Mengambil data lengkap user dalam 1 call (Hemat RPC request)
    function getFullProfile(address _user) external view returns (FullProfile memory fp) {
        LibIdentityStorage.Layout storage ids = LibIdentityStorage.layout();
        LibSocialStorage.Layout storage ss = LibSocialStorage.layout();
        
        uint256 tokenId = ids._addressToTokenId[_user];
        if (tokenId == 0) return fp; // Return empty

        LibSocialStorage.Profile storage p = ss.profiles[tokenId];
        
        fp.tokenId = tokenId;
        fp.handle = p.handle;
        fp.displayName = p.displayName;
        fp.avatarURI = p.avatarURI;
        
        // Ambil data lintas storage
        fp.reputation = LibReputationStorage.layout().reputationScore[tokenId];
        fp.followers = LibSocialGraphStorage.layout().followerCount[tokenId];
        fp.following = LibSocialGraphStorage.layout().followingCount[tokenId];
        fp.isPremium = ids.premiumExpirations[tokenId] > block.timestamp;
    }

    /// @notice Mengambil semua Badge ID milik user
    function getUserBadges(address _user) external view returns (uint256[] memory) {
        uint256 tokenId = LibIdentityStorage.layout()._addressToTokenId[_user];
        if (tokenId == 0) return new uint256[](0);
        return LibReputationStorage.layout().badges[tokenId];
    }
}
