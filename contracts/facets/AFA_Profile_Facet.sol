// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { LibDiamond } from "../diamond/libraries/LibDiamond.sol";
import { AppStorage } from "../storage/AppStorage.sol";

contract AFA_Profile_Facet {
    event HandleUpdated(uint256 indexed tokenId, string newHandle);
    event IdentityMetadataUpdated(uint256 indexed tokenId, string newMetadata);

    /// @notice Get the token ID of the caller. Reverts if caller has no identity.
    function getMyTokenId() public view returns (uint256) {
        uint256 tokenId = LibDiamond.appStorage().addressToTokenId[msg.sender];
        require(tokenId != 0, "AFA: You do not have an identity");
        return tokenId;
    }

    /// @notice Update your own @handle.
    function updateMyHandle(string memory newHandle) external {
        uint256 tokenId = getMyTokenId();
        // REKOMENDASI: Tambahkan pengecekan keunikan handle di sini
        LibDiamond.appStorage().handle[tokenId] = newHandle;
        emit HandleUpdated(tokenId, newHandle);
    }

    /// @notice Update your own identity metadata URI.
    function updateMyIdentityMetadata(string memory newMetadataUri) external {
        uint256 tokenId = getMyTokenId();
        LibDiamond.appStorage().identityMetadata[tokenId] = newMetadataUri;
        emit IdentityMetadataUpdated(tokenId, newMetadataUri);
    }

    /// @notice Burn your own identity. This action is irreversible.
    function burnMyIdentity() external {
        uint256 tokenId = getMyTokenId();
        AppStorage storage s = LibDiamond.appStorage();
        address owner = s.owners[tokenId]; // should be msg.sender

        // ERC721 State
        s.totalSupply -= 1;
        delete s.tokenApprovals[tokenId];
        s.balances[owner] -= 1;
        delete s.owners[tokenId];
        
        // Identity State
        delete s.addressToTokenId[owner];
        delete s.handle[tokenId];
        delete s.identityMetadata[tokenId];
        delete s.reputationScore[tokenId];
        delete s.isVerified[tokenId];
        delete s.createdAt[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    // Diperlukan agar event Transfer bisa di-emit dari facet ini
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
}
