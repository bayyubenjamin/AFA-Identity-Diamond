// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../storage/AppStorage.sol";

contract StakingFacet {
    AppStorage internal s;

    event Staked(uint256 indexed tokenId, uint256 amount);
    event Unstaked(uint256 indexed tokenId, uint256 amount);

    function stake(uint256 _tokenId) external payable {
        require(s.owners[_tokenId] == msg.sender, "Not token owner");
        require(msg.value > 0, "Cannot stake 0");

        s.stakedBalances[_tokenId] += msg.value;
        s.stakeUnlockTimes[_tokenId] = block.timestamp + 30 days; // Lock 30 hari

        emit Staked(_tokenId, msg.value);
    }

    function unstake(uint256 _tokenId) external {
        require(s.owners[_tokenId] == msg.sender, "Not token owner");
        require(block.timestamp >= s.stakeUnlockTimes[_tokenId], "Still locked");
        
        uint256 amount = s.stakedBalances[_tokenId];
        require(amount > 0, "No stake");

        s.stakedBalances[_tokenId] = 0;
        payable(msg.sender).transfer(amount);
        
        emit Unstaked(_tokenId, amount);
    }

    function getStakeInfo(uint256 _tokenId) external view returns (uint256 amount, uint256 unlockTime) {
        return (s.stakedBalances[_tokenId], s.stakeUnlockTimes[_tokenId]);
    }
}
