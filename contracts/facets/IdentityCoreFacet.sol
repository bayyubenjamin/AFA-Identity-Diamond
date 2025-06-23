// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../libraries/DiamondStorage.sol";
import "../interfaces/IDiamondLoupe.sol";
import "../interfaces/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract IdentityCoreFacet is IERC721Metadata {
    DiamondStorage internal s;

    // --- ERC721 View Functions ---
    function name() external pure returns (string memory) {
        return "AFA Identity";
    }

    function symbol() external pure returns (string memory) {
        return "AFAID";
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = s._tokenIdToAddress[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }
    
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return s._addressToTokenId[owner] != 0 ? 1 : 0;
    }
    
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(s._tokenIdToAddress[tokenId] != address(0), "ERC721: URI query for nonexistent token");
        string memory currentBaseURI = s.baseURI;
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, Strings.toString(tokenId)))
            : "";
    }

    // --- SOULBOUND IMPLEMENTATIONS ---
    // Implementasi fungsi-fungsi yang diperlukan oleh IERC721
    // tetapi kita buat agar me-revert untuk menjaga sifat soulbound.

    function approve(address to, uint256 tokenId) external pure {
        revert("AFA: Soulbound token cannot be approved");
    }

    function getApproved(uint256 tokenId) external pure returns (address operator) {
        return address(0);
    }

    function setApprovalForAll(address operator, bool _approved) external pure {
        revert("AFA: Soulbound token cannot be approved for all");
    }

    function isApprovedForAll(address owner, address operator) external pure returns (bool) {
        return false;
    }

    function transferFrom(address from, address to, uint256 tokenId) external pure {
        revert("AFA: Soulbound token cannot be transferred");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external pure {
        revert("AFA: Soulbound token cannot be transferred");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external pure {
        revert("AFA: Soulbound token cannot be transferred");
    }
    
    // --- ERC165 Support ---
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IDiamondLoupe).interfaceId;
    }
}
