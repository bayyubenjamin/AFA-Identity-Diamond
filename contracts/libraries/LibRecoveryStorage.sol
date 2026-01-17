// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library LibRecoveryStorage {
    bytes32 constant STORAGE_POSITION = keccak256("afa.identity.recovery.storage.v1");

    struct RecoveryRequest {
        address newOwnerAddress;
        uint256 executeAfter; // Timelock: Kapan recovery bisa dieksekusi
        uint256 approvalCount; // Berapa guardian yang sudah setuju
        bool executed;
    }

    struct Layout {
        // Identity Token ID => Daftar Address Guardian
        mapping(uint256 => address[]) guardians;
        
        // Identity Token ID => Mapping status guardian (untuk cek duplikat/validitas cepat)
        mapping(uint256 => mapping(address => bool)) isGuardian;
        
        // Identity Token ID => Request Pemulihan Aktif
        mapping(uint256 => RecoveryRequest) activeRecovery;
        
        // Identity Token ID => Mapping approval guardian untuk request saat ini
        mapping(uint256 => mapping(address => bool)) hasVoted;

        // Config Global
        uint256 recoveryDelay; // Waktu tunggu (misal: 24 jam) untuk mencegah hack instan
        uint256 minGuardians;  // Min guardian (misal: 3)
        uint256 threshold;     // Threshold (misal: 2 dari 3 harus setuju)
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
}
