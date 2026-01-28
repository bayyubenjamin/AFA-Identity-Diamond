// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library LibSocialGraphStorage {
    bytes32 constant STORAGE_POSITION = keccak256("afa.identity.socialgraph.storage.v1");

    struct Layout {
        // User A follows User B? [A][B] => bool
        mapping(uint256 => mapping(uint256 => bool)) isFollowing;
        // Jumlah pengikut
        mapping(uint256 => uint256) followerCount;
        // Jumlah yang diikuti
        mapping(uint256 => uint256) followingCount;
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly { s.slot := position }
    }
}
