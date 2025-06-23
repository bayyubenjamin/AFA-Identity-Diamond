// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../libraries/LibIdentityStorage.sol";
import "../interfaces/IDiamondLoupe.sol";
import "../interfaces/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract IdentityCoreFacet is IERC721Metadata {
    using LibIdentityStorage for LibIdentityStorage.Layout;

    // --- ERC721 View Functions ---

    /// @notice Returns the name of the token collection.
    function name() external pure override returns (string memory) {
        return "AFA Identity";
    }

    /// @notice Returns the symbol of the token.
    function symbol() external pure override returns (string memory) {
        return "AFAID";
    }

    /// @notice Returns the owner of a given tokenId.
    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = LibIdentityStorage.layout()._tokenIdToAddress[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /// @notice Returns balance of the given owner (always 0 or 1).
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return LibIdentityStorage.layout()._addressToTokenId[owner] != 0 ? 1 : 0;
    }

    /// @notice Returns token URI metadata.
    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        require(s._tokenIdToAddress[tokenId] != address(0), "ERC721: URI query for nonexistent token");
        return bytes(s.baseURI).length > 0
            ? string(abi.encodePacked(s.baseURI, Strings.toString(tokenId)))
            : "";
    }

    // --- Soulbound Logic ---

    function approve(address, uint256) external pure override {
        revert("AFA: Soulbound token cannot be approved");
    }

    function getApproved(uint256) external pure override returns (address) {
        return address(0);
    }

    function setApprovalForAll(address, bool) external pure override {
        revert("AFA: Soulbound token cannot be approved for all");
    }

    function isApprovedForAll(address, address) external pure override returns (bool) {
        return false;
    }

    function transferFrom(address, address, uint256) external pure override {
        revert("AFA: Soulbound token cannot be transferred");
    }

    function safeTransferFrom(address, address, uint256) external pure override {
        revert("AFA: Soulbound token cannot be transferred");
    }

    function safeTransferFrom(address, address, uint256, bytes calldata) external pure override {
        revert("AFA: Soulbound token cannot be transferred");
    }

    // --- ERC165 Interface Support ---

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IDiamondLoupe).interfaceId;
    }

    // --- Initialization Function (Only once) ---
    function initialize(address verifier, string memory _baseURI) external {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        require(s.verifierAddress == address(0), "Already initialized");
        s.verifierAddress = verifier;
        s.baseURI = _baseURI;
    }
}

