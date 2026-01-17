// Sources flattened with hardhat v2.26.3 https://hardhat.org

// SPDX-License-Identifier: MIT

// File contracts/interfaces/IOwnershipFacet.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.24;

interface IOwnershipFacet {
    function owner() external view returns (address owner_);
}


// File contracts/libraries/LibIdentityStorage.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.24;

library LibIdentityStorage {
    enum SubscriptionTier {
        ONE_MONTH,
        SIX_MONTHS,
        ONE_YEAR
    }

    struct Layout {
        mapping(address => uint256) _addressToTokenId;
        mapping(uint256 => address) _tokenIdToAddress;
        address verifierAddress;
        string baseURI;
        mapping(address => uint256) nonce;
        mapping(uint256 => uint256) premiumExpirations;
        
        mapping(SubscriptionTier => uint256) pricePerTierInWei;

        mapping(address => mapping(uint256 => uint256)) _ownedTokens;
        mapping(uint256 => uint256) _ownedTokensIndex;
        uint256[] _allTokens;
        mapping(uint256 => uint256) _allTokensIndex;
        mapping(uint256 => address) _owners;
        mapping(address => uint256) _balances;
        uint256 _tokenIdTracker;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("identity.storage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function _mint(Layout storage s, address to) internal returns (uint256 tokenId) {
        require(to != address(0), "mint to zero address");
        require(s._addressToTokenId[to] == 0, "AFA: Address already has an identity");

        tokenId = ++s._tokenIdTracker;
        s._tokenIdToAddress[tokenId] = to;
        s._addressToTokenId[to] = tokenId;
        s._owners[tokenId] = to;
        s._balances[to] += 1;

        uint256 len = s._balances[to] - 1;
        s._ownedTokens[to][len] = tokenId;
        s._ownedTokensIndex[tokenId] = len;
        s._allTokensIndex[tokenId] = s._allTokens.length;
        s._allTokens.push(tokenId);
    }
}


// File contracts/facets/SubscriptionManagerFacet.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.24;


contract SubscriptionManagerFacet {
    using LibIdentityStorage for LibIdentityStorage.Layout;

    event SubscriptionRenewed(uint256 indexed tokenId, uint256 newExpiration, LibIdentityStorage.SubscriptionTier tier);
    event PriceForTierSet(LibIdentityStorage.SubscriptionTier indexed tier, uint256 newPrice);

    function setPriceForTier(LibIdentityStorage.SubscriptionTier _tier, uint256 _newPriceInWei) external {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        require(msg.sender == IOwnershipFacet(address(this)).owner(), "AFA: Must be admin");
        s.pricePerTierInWei[_tier] = _newPriceInWei;
        emit PriceForTierSet(_tier, _newPriceInWei);
    }

    function getPriceForTier(LibIdentityStorage.SubscriptionTier _tier) external view returns (uint256) {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        return s.pricePerTierInWei[_tier];
    }

    function setPriceInWei(uint256 _newPriceInWei) external {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        require(msg.sender == IOwnershipFacet(address(this)).owner(), "AFA: Must be admin");
    }


    function priceInWei() external view returns (uint256) {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        return 0;
    }

    function upgradeToPremium(uint256 tokenId, LibIdentityStorage.SubscriptionTier tier) external payable {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        require(s._tokenIdToAddress[tokenId] == msg.sender, "Not token owner");

        uint256 requiredPrice = s.pricePerTierInWei[tier];
        require(requiredPrice > 0, "Premium price for this tier has not been set");
        require(msg.value >= requiredPrice, "Insufficient ETH payment for the selected tier");

        uint256 duration;
        if (tier == LibIdentityStorage.SubscriptionTier.ONE_MONTH) {
            duration = 30 days;
        } else if (tier == LibIdentityStorage.SubscriptionTier.SIX_MONTHS) {
            duration = 180 days;
        } else if (tier == LibIdentityStorage.SubscriptionTier.ONE_YEAR) {
            duration = 365 days;
        } else {
            revert("Invalid subscription tier");
        }

        uint256 currentExpiration = s.premiumExpirations[tokenId];
        uint256 startingPoint = (currentExpiration > block.timestamp) ? currentExpiration : block.timestamp;
        
        s.premiumExpirations[tokenId] = startingPoint + duration;

        emit SubscriptionRenewed(tokenId, s.premiumExpirations[tokenId], tier);
    }

    function getPremiumExpiration(uint256 tokenId) external view returns (uint256) {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        return s.premiumExpirations[tokenId];
    }

    function isPremium(uint256 tokenId) external view returns (bool) {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        return s.premiumExpirations[tokenId] > block.timestamp;
    }
}
