// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../storage/AppStorage.sol";
import "../diamond/libraries/LibDiamond.sol";

contract ReputationFacet {
    AppStorage internal s;

    event ReputationUpdated(uint256 indexed tokenId, uint256 newScore);

    // Hitung reputasi: (Umur Akun dalam hari * 1 poin) + (Verified * 50 poin) + Base Score
    function calculateReputation(uint256 _tokenId) public view returns (uint256) {
        require(s.owners[_tokenId] != address(0), "Identity not found");
        
        uint256 ageInDays = (block.timestamp - s.createdAt[_tokenId]) / 1 days;
        uint256 verificationBonus = s.isVerified[_tokenId] ? 50 : 0;
        uint256 currentBase = s.reputationScore[_tokenId];

        return currentBase + ageInDays + verificationBonus;
    }

    // Fungsi update manual oleh sistem/admin (misal user menyelesaikan quest)
    function boostReputation(uint256 _tokenId, uint256 _points) external {
        LibDiamond.enforceIsContractOwner();
        s.reputationScore[_tokenId] += _points;
        emit ReputationUpdated(_tokenId, calculateReputation(_tokenId));
    }
}
