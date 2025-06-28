// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../libraries/LibIdentityStorage.sol";
import "../interfaces/IOwnershipFacet.sol";

contract SubscriptionManagerFacet {
    using LibIdentityStorage for LibIdentityStorage.Layout;

    event SubscriptionRenewed(uint256 indexed tokenId, uint256 newExpiration);

    function setPriceInWei(uint256 _newPriceInWei) external {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        require(msg.sender == IOwnershipFacet(address(this)).owner(), "AFA: Must be admin");
        s.priceInWei = _newPriceInWei;
    }

    function priceInWei() external view returns (uint256) {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        return s.priceInWei;
    }

    function upgradeToPremium(uint256 tokenId) external payable {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        require(s._tokenIdToAddress[tokenId] == msg.sender, "Not token owner");

        uint256 requiredPrice = s.priceInWei;
        require(requiredPrice > 0, "Premium price not set");
        require(msg.value >= requiredPrice, "Insufficient ETH payment");

        s.premiumExpirations[tokenId] = block.timestamp + 30 days;

        emit SubscriptionRenewed(tokenId, s.premiumExpirations[tokenId]);
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
