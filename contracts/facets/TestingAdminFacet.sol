// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../libraries/LibIdentityStorage.sol";
import "../interfaces/IOwnershipFacet.sol";

contract TestingAdminFacet {
    // Start token IDs from 1
    uint256 private _nextTokenId;

    event AdminIdentityMinted(address indexed recipient, uint256 indexed tokenId);

    /**
     * @notice Mints a new identity for a user, bypassing payment and signature checks.
     * @dev Only the contract owner can call this function.
     * @param _recipient The address that will receive the new identity NFT.
     */
    function adminMint(address _recipient) external {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();

        require(msg.sender == IOwnershipFacet(address(this)).owner(), "AFA: Must be admin");
        require(_recipient != address(0), "AFA: Cannot mint to zero address");
        require(s._addressToTokenId[_recipient] == 0, "AFA: User already has an identity");

        if (_nextTokenId == 0) {
            _nextTokenId = 1;
        }

        uint256 tokenId = _nextTokenId;
        _nextTokenId++;

        s._addressToTokenId[_recipient] = tokenId;
        s._tokenIdToAddress[tokenId] = _recipient;

        s.premiumExpirations[tokenId] = block.timestamp + 365 days;

        emit AdminIdentityMinted(_recipient, tokenId);
    }
}

