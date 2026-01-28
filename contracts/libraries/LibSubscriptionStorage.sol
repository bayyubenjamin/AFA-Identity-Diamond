// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library LibSubscriptionStorage {
    bytes32 constant STORAGE_POSITION = keccak256("afa.identity.subscription.storage.v1");

    struct Layout {
        uint256 monthlyPrice;  // Harga per 30 hari dalam Wei
        address treasury;      // Wallet penampung dana
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly { s.slot := position }
    }
}
