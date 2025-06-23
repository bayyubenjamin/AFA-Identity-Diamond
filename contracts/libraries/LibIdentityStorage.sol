// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library LibIdentityStorage {
    bytes32 internal constant DIAMOND_STORAGE_POSITION = keccak256("afa.identity.storage");

    struct Layout {
        address verifierAddress;
        string baseURI;
        mapping(uint256 => address) _tokenIdToAddress;
        mapping(address => uint256) _addressToTokenId;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            l.slot := position
        }
    }
}

