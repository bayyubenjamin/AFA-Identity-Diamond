// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../libraries/LibIdentityStorage.sol";
import "../diamond/libraries/LibDiamond.sol";
import "../interfaces/IDiamondLoupe.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract IdentityCoreFacet is IERC721Metadata {
    using LibIdentityStorage for LibIdentityStorage.Layout;
    using Strings for uint256;
    using ECDSA for bytes32;

    // --- Custom Errors (Gas Efficiency & Clarity) ---
    error Identity_SoulboundTokenCannotBeTransferred();
    error Identity_AlreadyHasIdentity();
    error Identity_InvalidSignature();
    error Identity_NonExistentToken();
    error Identity_QueryForZeroAddress();
    error Identity_NotTokenOwner();
    error Identity_AlreadyInitialized();

    // --- Metadata ---

    function name() external pure override returns (string memory) {
        return "AFA Identity";
    }

    function symbol() external pure override returns (string memory) {
        return "AFAID";
    }

    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        if (s._tokenIdToAddress[tokenId] == address(0)) revert Identity_NonExistentToken();
        
        // Return baseURI + tokenId (Standard ERC721)
        // Frontend bisa fetch JSON ini untuk melihat status Premium/Basic
        return bytes(s.baseURI).length > 0
            ? string(abi.encodePacked(s.baseURI, tokenId.toString()))
            : "";
    }

    // --- ERC721 Standard Read ---

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = LibIdentityStorage.layout()._tokenIdToAddress[tokenId];
        if (owner == address(0)) revert Identity_NonExistentToken();
        return owner;
    }

    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert Identity_QueryForZeroAddress();
        return LibIdentityStorage.layout()._balances[owner];
    }

    // --- Soulbound Enforcement (SBT) ---
    // Semua fungsi transfer di-override untuk REVERT

    function approve(address, uint256) external pure override {
        revert Identity_SoulboundTokenCannotBeTransferred();
    }

    function getApproved(uint256) external pure override returns (address) {
        return address(0);
    }

    function setApprovalForAll(address, bool) external pure override {
        revert Identity_SoulboundTokenCannotBeTransferred();
    }

    function isApprovedForAll(address, address) external pure override returns (bool) {
        return false;
    }

    function transferFrom(address, address, uint256) external pure override {
        revert Identity_SoulboundTokenCannotBeTransferred();
    }

    function safeTransferFrom(address, address, uint256) external pure override {
        revert Identity_SoulboundTokenCannotBeTransferred();
    }

    function safeTransferFrom(address, address, uint256, bytes calldata) external pure override {
        revert Identity_SoulboundTokenCannotBeTransferred();
    }

    // --- Interface Support ---

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IDiamondLoupe).interfaceId;
    }

    // --- Core Logic ---

    function initialize(address verifier_, string memory _baseURI) external {
        LibDiamond.enforceIsOwner(); // Security: Only Owner
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        
        if (s.verifierAddress != address(0)) revert Identity_AlreadyInitialized();
        
        s.verifierAddress = verifier_;
        s.baseURI = _baseURI;
    }

    /// @notice Mint Identity dengan Signature Verifier (Sybil Resistance)
    /// @dev Menggunakan ChainID di hash untuk mencegah Replay Attack lintas chain
    function mintIdentity(bytes calldata _signature) external payable {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        address recipient = msg.sender;

        // 1. Cek apakah user sudah punya identity
        if (s._addressToTokenId[recipient] != 0) revert Identity_AlreadyHasIdentity();

        // 2. Konstruksi Hash yang Aman (Termasuk ChainID!)
        // Format: Hash(Address + Nonce + ChainID)
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                recipient, 
                s.nonce[recipient], 
                block.chainid // High Impact: Cross-chain Replay Protection
            )
        );

        // 3. Ubah ke Ethereum Signed Message Hash
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(messageHash);

        // 4. Recover Signer
        address signer = ethSignedMessageHash.recover(_signature);

        // 5. Verifikasi Signer adalah Admin/Verifier yang sah
        if (signer != s.verifierAddress) revert Identity_InvalidSignature();

        // 6. Eksekusi Minting & Increment Nonce
        s.nonce[recipient]++;
        uint256 tokenId = s._mint(recipient);
        
        emit Transfer(address(0), recipient, tokenId);
    }
    
    /// @notice User bisa membakar identitas mereka sendiri (Privacy Compliance)
    function burnIdentity(uint256 tokenId) external {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        
        if (s._tokenIdToAddress[tokenId] != msg.sender) revert Identity_NotTokenOwner();
        
        // Logic penghapusan (Sederhana: set owner ke 0, hapus lookup)
        // Catatan: Logic lengkap burn harus menghapus dari enumerable array juga,
        // tapi untuk efisiensi di snippet ini kita hapus mapping utama.
        // *Idealnya panggil fungsi internal _burn di library*
        
        delete s._tokenIdToAddress[tokenId];
        delete s._addressToTokenId[msg.sender];
        s._balances[msg.sender] -= 1;
        
        emit Transfer(msg.sender, address(0), tokenId);
    }

    // --- View Functions ---

    function getIdentity(address _user) external view returns (uint256 tokenId, uint256 premiumExpiration, bool isPremium) {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        tokenId = s._addressToTokenId[_user];
        if (tokenId != 0) {
            premiumExpiration = s.premiumExpirations[tokenId];
            isPremium = premiumExpiration >= block.timestamp;
        }
    }

    function verifier() external view returns (address) {
        return LibIdentityStorage.layout().verifierAddress;
    }
    
    /// @notice Admin update Base URI untuk metadata
    function setBaseURI(string memory _newBaseURI) external {
        LibDiamond.enforceIsOwner();
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        s.baseURI = _newBaseURI;
    }
}
