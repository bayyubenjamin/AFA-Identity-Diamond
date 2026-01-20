// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../storage/AppStorage.sol";

contract GovernanceFacet {
    AppStorage internal s;

    event ProposalCreated(uint256 indexed proposalId, string description, uint256 endTime);
    event Voted(uint256 indexed proposalId, uint256 indexed tokenId);

    modifier onlyIdentityOwner(uint256 _tokenId) {
        require(s.owners[_tokenId] == msg.sender, "Not token owner");
        _;
    }

    function createProposal(uint256 _tokenId, string memory _desc) external onlyIdentityOwner(_tokenId) {
        require(s.reputationScore[_tokenId] > 10, "Reputation too low to propose");
        
        s.proposalCount++;
        uint256 pId = s.proposalCount;
        
        Proposal storage p = s.proposals[pId];
        p.id = pId;
        p.proposer = msg.sender;
        p.description = _desc;
        p.endTime = block.timestamp + 3 days;
        
        emit ProposalCreated(pId, _desc, p.endTime);
    }

    function vote(uint256 _tokenId, uint256 _proposalId) external onlyIdentityOwner(_tokenId) {
        Proposal storage p = s.proposals[_proposalId];
        require(block.timestamp < p.endTime, "Voting ended");
        require(!p.hasVoted[_tokenId], "Already voted");

        p.hasVoted[_tokenId] = true;
        p.voteCount++;
        
        emit Voted(_proposalId, _tokenId);
    }

    function getProposal(uint256 _proposalId) external view returns (string memory desc, uint256 votes, bool active) {
        Proposal storage p = s.proposals[_proposalId];
        return (p.description, p.voteCount, block.timestamp < p.endTime);
    }
}
