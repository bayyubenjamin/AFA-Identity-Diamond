// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// This struct holds all the state variables for the diamond.
// By placing them here, we prevent storage collisions between facets.
struct DiamondStorage {
    // from IdentityCoreFacet
    string baseURI;
    mapping(address => uint256) _addressToTokenId;
    mapping(uint256 => address) _tokenIdToAddress;

    // from AttestationFacet
    mapping(uint256 => Attestation) premiumStatus;

    // from SubscriptionManagerFacet
    uint256 priceInUSD; // Price in cents, e.g., $1.00 is 100
    address verifierAddress;
    mapping(address => address) acceptedTokens; // token address => price feed address
}

// Struct ini juga harus didefinisikan di sini karena digunakan di dalam DiamondStorage
struct Attestation {
    uint256 expirationTimestamp;
    address issuer;
}
