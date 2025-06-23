// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../libraries/DiamondStorage.sol";

contract AttestationFacet {
    DiamondStorage internal s;

    // --- Public View Functions ---

    /**
     * @notice Checks if an identity's premium subscription is currently active.
     * @param tokenId The ID of the token to check.
     * @return True if the subscription is active, false otherwise.
     */
    function isPremium(uint256 tokenId) public view returns (bool) {
        Attestation storage att = s.premiumStatus[tokenId];
        if (att.issuer == address(0)) {
            return false;
        }
        return block.timestamp < att.expirationTimestamp;
    }

    /**
     * @notice Gets the expiration timestamp for an identity's premium subscription.
     * @param tokenId The ID of the token to check.
     * @return The Unix timestamp of when the subscription expires.
     */
    function getPremiumExpiration(uint256 tokenId) public view returns (uint256) {
        return s.premiumStatus[tokenId].expirationTimestamp;
    }
}
