// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../libraries/LibIdentityStorage.sol";
import "../interfaces/IOwnershipFacet.sol";

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
