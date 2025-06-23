// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../libraries/DiamondStorage.sol";

contract AttestationFacet {
    AppStorage internal s;

    // --- Internal Function ---
    function _addPremiumAttestation(uint256 tokenId) internal {
        require(s._tokenIdToAddress[tokenId] != address(0), "Token does not exist");
        s.premiumStatus[tokenId] = Attestation({
            expirationTimestamp: block.timestamp + 365 days,
            issuer: address(this)
        });
    }

    // --- Public View Functions ---
    function isPremium(uint256 tokenId) public view returns (bool) {
        Attestation storage att = s.premiumStatus[tokenId];
        if (att.issuer == address(0)) {
            return false;
        }
        return block.timestamp < att.expirationTimestamp;
    }

    function getPremiumExpiration(uint256 tokenId) public view returns (uint256) {
        return s.premiumStatus[tokenId].expirationTimestamp;
    }
}
