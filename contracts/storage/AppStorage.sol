// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title AppStorage
/// @notice Struktur penyimpanan utama untuk Diamond AFA Identity.
/// Semua facet akan menggunakan struktur ini agar tidak terjadi storage collision.
struct AppStorage {
    // ==== ERC721 Metadata ====
    string name;
    string symbol;

    // ==== ERC721 Standar ====
    mapping(uint256 => address) owners; // pemilik token
    mapping(address => uint256) balances; // jumlah token per address
    mapping(uint256 => address) tokenApprovals; // approval spesifik per token
    mapping(address => mapping(address => bool)) operatorApprovals; // approval global

    uint256 totalSupply; // total NFT tercetak
    uint256 currentTokenId; // id terakhir yang dicetak

    // ==== Identitas NFT ====
    mapping(uint256 => string) identityMetadata; // metadata identitas (nama, avatar, dsb dalam format JSON URI)
    mapping(uint256 => string) handle; // @handle unik per NFT
    // REKOMENDASI: Untuk memastikan handle unik, Anda perlu mapping sebaliknya.
    // mapping(string => bool) isHandleTaken; atau mapping(string => uint256) handleToTokenId;

    // ==== Integrasi Web3 Tambahan ====
    mapping(address => uint256) addressToTokenId; // agar 1 address hanya punya 1 ID
    mapping(uint256 => uint256) reputationScore; // sistem reputasi opsional (0-100 misalnya)

    // ==== Verifikasi & Status ====
    mapping(uint256 => bool) isVerified; // apakah NFT identity sudah diverifikasi
    mapping(uint256 => uint256) createdAt; // timestamp minting

    // ==== Admin & Ownership ====
    address contractOwner; // pemilik diamond utama
    mapping(address => bool) admins; // address yang bisa ubah status user

    // ==== Anti Sybil / Proof of Human ====
    mapping(bytes32 => bool) usedProofHashes; // untuk menyimpan hash bukti manusia yang sudah dipakai
}
