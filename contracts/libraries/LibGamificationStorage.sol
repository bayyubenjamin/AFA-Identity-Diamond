// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library LibGamificationStorage {
    bytes32 constant STORAGE_POSITION = keccak256("afa.identity.gamification.storage.v1");

    struct Layout {
        mapping(uint256 => uint256) xp;
        mapping(uint256 => uint256) lastActionTime;
        // TokenID -> QuestHash -> Completed
        mapping(uint256 => mapping(bytes32 => bool)) questCompleted; 
        uint256 xpPerDailyActive;
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly { s.slot := position }
    }
}
