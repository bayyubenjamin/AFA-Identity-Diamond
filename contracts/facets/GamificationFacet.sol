// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { LibIdentityStorage } from "../libraries/LibIdentityStorage.sol";
import { LibDiamond } from "../diamond/libraries/LibDiamond.sol";

library LibGamificationStorage {
    bytes32 constant STORAGE_POSITION = keccak256("afa.identity.gamification.storage.v1");
    struct Layout {
        mapping(uint256 => uint256) xp;
        mapping(uint256 => uint256) lastActionTime;
        mapping(uint256 => mapping(bytes32 => bool)) questCompleted; // TokenID -> QuestHash -> Completed
        uint256 xpPerDailyActive;
    }
    function layout() internal pure returns (Layout storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly { s.slot := position }
    }
}

contract GamificationFacet {
    
    event XPAdded(uint256 indexed tokenId, uint256 amount, string reason);
    event LevelUp(uint256 indexed tokenId, uint256 newLevel);
    event QuestCompleted(uint256 indexed tokenId, string questId, uint256 reward);

    modifier onlyAdmin() {
        LibDiamond.enforceIsOwner();
        _;
    }

    // --- Admin ---

    function addXP(uint256 _tokenId, uint256 _amount, string calldata _reason) external onlyAdmin {
        _addXP(_tokenId, _amount, _reason);
    }

    function setDailyReward(uint256 _amount) external onlyAdmin {
        LibGamificationStorage.layout().xpPerDailyActive = _amount;
    }

    // --- User Actions ---

    function dailyCheckIn() external {
        LibIdentityStorage.Layout storage ids = LibIdentityStorage.layout();
        uint256 tokenId = ids._addressToTokenId[msg.sender];
        require(tokenId != 0, "No Identity");

        LibGamificationStorage.Layout storage gs = LibGamificationStorage.layout();
        require(block.timestamp >= gs.lastActionTime[tokenId] + 1 days, "Already checked in today");
        
        gs.lastActionTime[tokenId] = block.timestamp;
        
        uint256 reward = gs.xpPerDailyActive == 0 ? 10 : gs.xpPerDailyActive;
        _addXP(tokenId, reward, "Daily Check-in");
    }

    // --- Quest System ---

    /// @notice Menyelesaikan quest (bisa dipanggil admin atau logic contract lain via diamond cut permission)
    /// @param _questId Unique ID string, misal "PROFILE_SETUP"
    function completeQuest(uint256 _tokenId, string calldata _questId, uint256 _reward) external onlyAdmin {
        LibGamificationStorage.Layout storage gs = LibGamificationStorage.layout();
        bytes32 qHash = keccak256(abi.encodePacked(_questId));
        
        require(!gs.questCompleted[_tokenId][qHash], "Quest already completed");
        
        gs.questCompleted[_tokenId][qHash] = true;
        emit QuestCompleted(_tokenId, _questId, _reward);
        
        _addXP(_tokenId, _reward, string(abi.encodePacked("Quest: ", _questId)));
    }

    // --- View Functions ---

    function getLevel(uint256 _tokenId) public view returns (uint256) {
        uint256 xp = LibGamificationStorage.layout().xp[_tokenId];
        if (xp == 0) return 1;
        return (xp / 100) + 1;
    }

    function getXP(uint256 _tokenId) external view returns (uint256) {
        return LibGamificationStorage.layout().xp[_tokenId];
    }
    
    function isQuestCompleted(uint256 _tokenId, string calldata _questId) external view returns (bool) {
         return LibGamificationStorage.layout().questCompleted[_tokenId][keccak256(abi.encodePacked(_questId))];
    }

    // --- Internal ---

    function _addXP(uint256 _tokenId, uint256 _amount, string memory _reason) internal {
        LibGamificationStorage.Layout storage gs = LibGamificationStorage.layout();
        uint256 oldLevel = getLevel(_tokenId);
        gs.xp[_tokenId] += _amount;
        uint256 newLevel = getLevel(_tokenId);

        emit XPAdded(_tokenId, _amount, _reason);
        if (newLevel > oldLevel) {
            emit LevelUp(_tokenId, newLevel);
        }
    }
}
