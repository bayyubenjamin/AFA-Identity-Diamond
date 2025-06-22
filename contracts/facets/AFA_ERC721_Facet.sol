// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { LibDiamond } from "../diamond/libraries/LibDiamond.sol";
import { AppStorage } from "../storage/AppStorage.sol";

// --- PERBAIKAN: Menambahkan semua import yang dibutuhkan ---
import "@openzeppelin/contracts/interfaces/IERC721Metadata.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";


contract AFA_ERC721_Facet is IERC721Metadata {

    // =============================================================
    //                    ERC721 METADATA VIEW FUNCTIONS
    // =============================================================
    function name() external view returns (string memory) {
        return LibDiamond.appStorage().name;
    }

    function symbol() external view returns (string memory) {
        return LibDiamond.appStorage().symbol;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        _requireMinted(tokenId);
        return LibDiamond.appStorage().identityMetadata[tokenId];
    }
    
    // =============================================================
    //                    ERC721 VIEW FUNCTIONS
    // =============================================================
    function balanceOf(address owner) external view returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return LibDiamond.appStorage().balances[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = LibDiamond.appStorage().owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    // --- PERBAIKAN: Mengubah external menjadi public ---
    function getApproved(uint256 tokenId) public view returns (address) {
        _requireMinted(tokenId);
        return LibDiamond.appStorage().tokenApprovals[tokenId];
    }

    // --- PERBAIKAN: Mengubah external menjadi public ---
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return LibDiamond.appStorage().operatorApprovals[owner][operator];
    }

    // =============================================================
    //                    ERC721 STATE-CHANGING FUNCTIONS
    // =============================================================
    function approve(address to, uint256 tokenId) external {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender), // Sekarang bisa dipanggil
            "ERC721: approve caller is not owner nor approved for all"
        );
        LibDiamond.appStorage().tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) external {
        AppStorage storage s = LibDiamond.appStorage();
        s.operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    
    function transferFrom(address from, address to, uint256 tokenId) public {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        
        AppStorage storage s = LibDiamond.appStorage();
        delete s.tokenApprovals[tokenId];
        s.balances[from] -= 1;
        s.balances[to] += 1;
        s.owners[tokenId] = to;
        delete s.addressToTokenId[from];
        s.addressToTokenId[to] = tokenId;
        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non-ERC721Receiver implementer");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    // =============================================================
    //                    ERC165 SUPPORT
    // =============================================================
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId || // Sekarang dikenali
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC165).interfaceId; // Sekarang dikenali
    }

    // =============================================================
    //                    INTERNAL HELPER FUNCTIONS
    // =============================================================
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender || // Sekarang bisa dipanggil
            isApprovedForAll(owner, spender)); // Sekarang bisa dipanggil
    }

    function _requireMinted(uint256 tokenId) internal view {
        // Cukup gunakan ownerOf, karena sudah ada require di dalamnya
        ownerOf(tokenId);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector; // Sekarang dikenali
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non-ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
}
