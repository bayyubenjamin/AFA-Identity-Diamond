// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { LibDiamond } from "../diamond/libraries/LibDiamond.sol";
// Kita perlu interface untuk membaca data dari facet lain (Cross-Facet Communication)
interface IGamification {
    function getLevel(uint256 _tokenId) external view returns (uint256);
}
interface IReputation {
    function getReputation(uint256 _tokenId) external view returns (uint256);
}

library LibGovernanceStorage {
    bytes32 constant STORAGE_POSITION = keccak256("afa.identity.governance.storage.v1");

    struct Proposal {
        string description;
        uint256 voteCount;
        uint256 deadline;
        bool executed;
        mapping(uint256 => bool) hasVoted; // TokenID -> Status
    }

    struct Layout {
        uint256 proposalCount;
        mapping(uint256 => Proposal) proposals;
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly { s.slot := position }
    }
}

contract GovernanceFacet {
    event ProposalCreated(uint256 indexed proposalId, string description, uint256 deadline);
    event Voted(uint256 indexed proposalId, uint256 indexed tokenId, uint256 weight);

    // --- Logic ---

    function createProposal(string calldata _desc, uint256 _durationSeconds) external {
        LibDiamond.enforceIsOwner(); // Hanya admin yang buat proposal untuk saat ini
        LibGovernanceStorage.Layout storage gs = LibGovernanceStorage.layout();
        
        uint256 newId = gs.proposalCount++;
        LibGovernanceStorage.Proposal storage p = gs.proposals[newId];
        p.description = _desc;
        p.deadline = block.timestamp + _durationSeconds;
        p.voteCount = 0;
        p.executed = false;

        emit ProposalCreated(newId, _desc, p.deadline);
    }

    function vote(uint256 _proposalId, uint256 _tokenId) external {
        // Validasi kepemilikan token sebaiknya dilakukan di sisi UI/EIP-712 signature untuk gas efficiency
        // Di sini kita asumsikan msg.sender adalah owner atau dipanggil via meta-tx
        
        LibGovernanceStorage.Layout storage gs = LibGovernanceStorage.layout();
        LibGovernanceStorage.Proposal storage p = gs.proposals[_proposalId];

        require(block.timestamp < p.deadline, "Voting ended");
        require(!p.hasVoted[_tokenId], "Already voted");

        // Hitung Voting Power: Level + (Reputation / 10)
        uint256 level = IGamification(address(this)).getLevel(_tokenId);
        uint256 reputation = IReputation(address(this)).getReputation(_tokenId);
        
        uint256 power = level + (reputation / 10);
        
        p.voteCount += power;
        p.hasVoted[_tokenId] = true;

        emit Voted(_proposalId, _tokenId, power);
    }

    // --- View ---
    function getProposal(uint256 _proposalId) external view returns (string memory desc, uint256 votes, uint256 deadline, bool active) {
        LibGovernanceStorage.Proposal storage p = LibGovernanceStorage.layout().proposals[_proposalId];
        return (p.description, p.voteCount, p.deadline, block.timestamp < p.deadline);
    }
}
