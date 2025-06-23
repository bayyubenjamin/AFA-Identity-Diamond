pragma solidity ^0.8.24;

struct DiamondStorage {
    string baseURI;
    mapping(address => uint256) _addressToTokenId;
    mapping(uint256 => address) _tokenIdToAddress;

    mapping(uint256 => Attestation) premiumStatus;

    uint256 priceInUSD;
    address verifierAddress;
    mapping(address => address) acceptedTokens;

    address contractOwner;
}

struct Attestation {
    uint256 expirationTimestamp;
    address issuer;
}
