// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../libraries/LibIdentityStorage.sol";
import "../interfaces/IOwnershipFacet.sol";

contract SubscriptionManagerFacet {
    using LibIdentityStorage for LibIdentityStorage.Layout;

    event SubscriptionRenewed(uint256 indexed tokenId, uint256 newExpiration);

    /**
     * Set harga dalam cent USD (misal: 500 = $5.00)
     */
    function setPriceInUSD(uint256 _priceInCents) external {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        require(msg.sender == IOwnershipFacet(address(this)).owner(), "AFA: Must be admin");
        s.priceInUSD = _priceInCents;
    }

    /**
     * Ambil harga premium
     */
    function priceInCents() external view returns (uint256) {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        return s.priceInUSD;
    }

    /**
     * Upgrade NFT ke premium
     */
    function upgradeToPremium(uint256 tokenId) external payable {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        require(s._tokenIdToAddress[tokenId] == msg.sender, "Not token owner");

        uint256 requiredPrice = s.priceInUSD;
        require(requiredPrice > 0, "Premium price not set");
        require(msg.value >= requiredPrice, "Insufficient payment");

        s.premiumExpirations[tokenId] = block.timestamp + 30 days;

        emit SubscriptionRenewed(tokenId, s.premiumExpirations[tokenId]);
    }

    /**
     * Cek kapan masa premium habis
     */
    function getPremiumExpiration(uint256 tokenId) external view returns (uint256) {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        return s.premiumExpirations[tokenId];
    }

    /**
     * Apakah tokenId masih premium
     */
    function isPremium(uint256 tokenId) external view returns (bool) {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        return s.premiumExpirations[tokenId] > block.timestamp;
    }
}

