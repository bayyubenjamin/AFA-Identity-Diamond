// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { LibIdentityStorage } from "../libraries/LibIdentityStorage.sol";
import { LibDiamond } from "../diamond/libraries/LibDiamond.sol";

// Kita gunakan struct internal library di sini agar file tetap compact (3 files requirement)
library LibGamificationStorage {
    bytes32 constant STORAGE_POSITION = keccak256("afa.identity.gamification.storage.v1");

    struct Layout {
        mapping(uint256 => uint256) xp; // TokenID -> Experience Points
        mapping(uint256 => uint256) lastActionTime; // Cooldown logic
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

    modifier onlyAdmin() {
        LibDiamond.enforceIsOwner();
        _;
    }

    // --- Admin Functions ---

    function addXP(uint256 _tokenId, uint256 _amount, string calldata _reason) external onlyAdmin {
        _addXP(_tokenId, _amount, _reason);
    }

    // --- Public Logic ---

    /// @notice Klaim XP harian (Daily Check-in)
    function dailyCheckIn() external {
        LibIdentityStorage.Layout storage ids = LibIdentityStorage.layout();
        uint256 tokenId = ids._addressToTokenId[msg.sender];
        require(tokenId != 0, "No Identity");

        LibGamificationStorage.Layout storage gs = LibGamificationStorage.layout();
        
        // Cek Cooldown (1 hari)
        require(block.timestamp >= gs.lastActionTime[tokenId] + 1 days, "Already checked in today");

        gs.lastActionTime[tokenId] = block.timestamp;
        
        // Default 10 XP jika belum diset admin
        uint256 reward = gs.xpPerDailyActive == 0 ? 10 : gs.xpPerDailyActive;
        
        _addXP(tokenId, reward, "Daily Check-in");
    }

    // --- View Functions ---

    function getLevel(uint256 _tokenId) public view returns (uint256) {
        uint256 xp = LibGamificationStorage.layout().xp[_tokenId];
        // Rumus Level Simple: Level = sqrt(XP)
        // 100 XP = Lvl 10, 400 XP = Lvl 20
        // Atau: Level = XP / 100 + 1
        if (xp == 0) return 1;
        return (xp / 100) + 1;
    }

    function getXP(uint256 _tokenId) external view returns (uint256) {
        return LibGamificationStorage.layout().xp[_tokenId];
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
