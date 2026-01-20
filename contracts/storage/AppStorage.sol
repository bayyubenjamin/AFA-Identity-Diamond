// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title AppStorage
/// @notice Struktur penyimpanan utama untuk Diamond AFA Identity.
/// Semua facet akan menggunakan struktur ini agar tidak terjadi storage collision.

struct Proposal {
    uint256 id;
    address proposer;
    string description;
    uint256 voteCount;
    uint256 endTime;
    bool executed;
    mapping(uint256 => bool) hasVoted; // tokenId => status
}

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
    mapping(uint256 => string) identityMetadata; // metadata identitas
    mapping(uint256 => string) handle; // @handle unik per NFT
    // REKOMENDASI: Tambahkan reverse mapping untuk check uniqueness handle
    mapping(string => uint256) handleToTokenId; 

    // ==== Integrasi Web3 Tambahan ====
    mapping(address => uint256) addressToTokenId; // agar 1 address hanya punya 1 ID
    mapping(uint256 => uint256) reputationScore; // sistem reputasi opsional (0-100)

    // ==== Verifikasi & Status ====
    mapping(uint256 => bool) isVerified; // apakah NFT identity sudah diverifikasi
    mapping(uint256 => uint256) createdAt; // timestamp minting

    // ==== Admin & Ownership ====
    address contractOwner; // pemilik diamond utama
    mapping(address => bool) admins; // address yang bisa ubah status user

    // ==== Anti Sybil / Proof of Human ====
    mapping(bytes32 => bool) usedProofHashes; // hash bukti manusia yang sudah dipakai

    // ==========================================================
    // ==== NEW STATE VARIABLES (HIGH IMPACT UPDATE) ====
    // ==========================================================

    // ---- 1. Governance Storage ----
    uint256 proposalCount;
    mapping(uint256 => Proposal) proposals; // proposalId => Proposal Struct

    // ---- 2. Staking Storage ----
    mapping(uint256 => uint256) stakedBalances; // tokenId => amount staked
    mapping(uint256 => uint256) stakeUnlockTimes; // tokenId => unlock timestamp
}
