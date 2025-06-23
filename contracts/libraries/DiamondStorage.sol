// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Struct untuk data atestasi
struct Attestation {
    uint256 expirationTimestamp;
    address issuer;
}

// Struct utama untuk semua state variabel diamond
struct AppStorage {
    // Variabel untuk SubscriptionManagerFacet
    address contractOwner;
    address verifierAddress;
    uint256 priceInUSD; // dalam sen
    mapping(address => uint256) _addressToTokenId;

    // Variabel untuk IdentityCoreFacet
    mapping(uint256 => address) _tokenIdToAddress;
    string baseURI;

    // Variabel untuk AttestationFacet
    mapping(uint256 => Attestation) premiumStatus;
}

library DiamondStorage {
    bytes32 internal constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    function diamondStorage() internal pure returns (AppStorage storage s) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
}
