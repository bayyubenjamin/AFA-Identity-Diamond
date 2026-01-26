// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { LibDiamond } from "../diamond/libraries/LibDiamond.sol";
import { LibIdentityStorage } from "../libraries/LibIdentityStorage.sol";

library LibStakingStorage {
    bytes32 constant STORAGE_POSITION = keccak256("afa.identity.staking.storage.v1");

    struct Layout {
        // TokenID -> Staked Amount (Native Token)
        mapping(uint256 => uint256) stakedBalance;
        // TokenID -> Waktu mulai staking
        mapping(uint256 => uint256) stakingStartTime;
        // Minimum stake amount
        uint256 minStake;
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly { s.slot := position }
    }
}

contract StakingFacet {
    event Staked(uint256 indexed tokenId, uint256 amount);
    event Unstaked(uint256 indexed tokenId, uint256 amount);

    function setMinStake(uint256 _amount) external {
        LibDiamond.enforceIsOwner();
        LibStakingStorage.layout().minStake = _amount;
    }

    function stake(uint256 _tokenId) external payable {
        require(msg.value > 0, "Cannot stake 0");
        
        // Verifikasi kepemilikan identity
        LibIdentityStorage.Layout storage isStore = LibIdentityStorage.layout();
        require(isStore._tokenIdToAddress[_tokenId] == msg.sender, "Not identity owner");

        LibStakingStorage.Layout storage ss = LibStakingStorage.layout();
        
        ss.stakedBalance[_tokenId] += msg.value;
        if (ss.stakingStartTime[_tokenId] == 0) {
            ss.stakingStartTime[_tokenId] = block.timestamp;
        }

        emit Staked(_tokenId, msg.value);
    }

    function unstake(uint256 _tokenId, uint256 _amount) external {
        LibIdentityStorage.Layout storage isStore = LibIdentityStorage.layout();
        require(isStore._tokenIdToAddress[_tokenId] == msg.sender, "Not identity owner");

        LibStakingStorage.Layout storage ss = LibStakingStorage.layout();
        require(ss.stakedBalance[_tokenId] >= _amount, "Insufficient stake");

        ss.stakedBalance[_tokenId] -= _amount;
        if (ss.stakedBalance[_tokenId] == 0) {
            ss.stakingStartTime[_tokenId] = 0;
        }

        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Transfer failed");

        emit Unstaked(_tokenId, _amount);
    }

    function getStakeInfo(uint256 _tokenId) external view returns (uint256 amount, uint256 duration) {
        LibStakingStorage.Layout storage ss = LibStakingStorage.layout();
        amount = ss.stakedBalance[_tokenId];
        if (ss.stakingStartTime[_tokenId] != 0) {
            duration = block.timestamp - ss.stakingStartTime[_tokenId];
        } else {
            duration = 0;
        }
    }
}
