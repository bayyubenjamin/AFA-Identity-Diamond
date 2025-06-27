// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../libraries/LibIdentityStorage.sol";

contract AttestationFacet {
    /**
     * @notice Checks if an identity's premium subscription is currently active.
     * @param tokenId The ID of the token to check.
     * @return True if the subscription is active, false otherwise.
     */
    function isPremium(uint256 tokenId) public view returns (bool) {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        return s.premiumExpirations[tokenId] > block.timestamp;
    }

    /**
     * @notice Gets the expiration timestamp for an identity's premium subscription.
     * @param tokenId The ID of the token to check.
     * @return The Unix timestamp of when the subscription expires.
     */
    function getPremiumExpiration(uint256 tokenId) public view returns (uint256) {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        return s.premiumExpirations[tokenId];
    }
}

