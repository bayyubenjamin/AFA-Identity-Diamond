// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { LibRecoveryStorage } from "../libraries/LibRecoveryStorage.sol";
import { LibIdentityStorage } from "../libraries/LibIdentityStorage.sol";
import { LibDiamond } from "../diamond/libraries/LibDiamond.sol";

contract SocialRecoveryFacet {
    
    // Events
    event GuardianAdded(uint256 indexed tokenId, address indexed guardian);
    event GuardianRemoved(uint256 indexed tokenId, address indexed guardian);
    event RecoveryInitiated(uint256 indexed tokenId, address newOwner, address initiator);
    event RecoverySupported(uint256 indexed tokenId, address guardian);
    event RecoveryExecuted(uint256 indexed tokenId, address oldOwner, address newOwner);

    // Errors
    error Recovery_OnlyIdentityOwner();
    error Recovery_InvalidGuardian();
    error Recovery_GuardianAlreadyExists();
    error Recovery_GuardianNotFound();
    error Recovery_NotAGuardian();
    error Recovery_RequestNotFound();
    error Recovery_AlreadyVoted();
    error Recovery_TimelockNotExpired();
    error Recovery_InsufficientVotes();
    error Recovery_NewOwnerHasIdentity();

    // --- Modifiers ---
    modifier onlyIdentityOwner() {
        LibIdentityStorage.Layout storage ids = LibIdentityStorage.layout();
        uint256 tokenId = ids._addressToTokenId[msg.sender];
        if (tokenId == 0 || ids._tokenIdToAddress[tokenId] != msg.sender) 
            revert Recovery_OnlyIdentityOwner();
        _;
    }

    // --- User: Manage Guardians ---

    function addGuardian(address _guardian) external onlyIdentityOwner {
        if (_guardian == address(0) || _guardian == msg.sender) revert Recovery_InvalidGuardian();
        
        LibIdentityStorage.Layout storage ids = LibIdentityStorage.layout();
        uint256 tokenId = ids._addressToTokenId[msg.sender];
        
        LibRecoveryStorage.Layout storage rs = LibRecoveryStorage.layout();
        
        if (rs.isGuardian[tokenId][_guardian]) revert Recovery_GuardianAlreadyExists();

        rs.guardians[tokenId].push(_guardian);
        rs.isGuardian[tokenId][_guardian] = true;
        
        emit GuardianAdded(tokenId, _guardian);
    }

    // --- Guardian: Recovery Process ---

    /// @notice Guardian memulai atau mendukung proses pemulihan akun teman
    function supportRecovery(uint256 _tokenId, address _newOwner) external {
        LibRecoveryStorage.Layout storage rs = LibRecoveryStorage.layout();
        
        // 1. Cek apakah msg.sender adalah guardian valid
        if (!rs.isGuardian[_tokenId][msg.sender]) revert Recovery_NotAGuardian();

        LibRecoveryStorage.RecoveryRequest storage req = rs.activeRecovery[_tokenId];

        // 2. Jika request belum ada atau untuk address beda, reset/buat baru
        if (req.newOwnerAddress != _newOwner) {
            req.newOwnerAddress = _newOwner;
            req.approvalCount = 0;
            req.executeAfter = block.timestamp + 1 days; // Hardcoded delay 1 hari
            req.executed = false;
            // Reset votes logic perlu penanganan lebih kompleks di real prod, 
            // di sini kita simplifikasi: request baru override yg lama.
            emit RecoveryInitiated(_tokenId, _newOwner, msg.sender);
        }

        // 3. Catat Vote
        if (rs.hasVoted[_tokenId][msg.sender]) revert Recovery_AlreadyVoted();
        
        rs.hasVoted[_tokenId][msg.sender] = true;
        req.approvalCount++;

        emit RecoverySupported(_tokenId, msg.sender);
    }

    /// @notice Eksekusi pemindahan akun setelah threshold tercapai
    function executeRecovery(uint256 _tokenId) external {
        LibRecoveryStorage.Layout storage rs = LibRecoveryStorage.layout();
        LibRecoveryStorage.RecoveryRequest storage req = rs.activeRecovery[_tokenId];

        if (req.newOwnerAddress == address(0)) revert Recovery_RequestNotFound();
        if (req.executed) revert Recovery_RequestNotFound();
        if (block.timestamp < req.executeAfter) revert Recovery_TimelockNotExpired();

        // Cek Threshold (Misal hardcoded min 2 suara atau 50% guardian)
        uint256 totalGuardians = rs.guardians[_tokenId].length;
        uint256 threshold = totalGuardians / 2 + 1; // Simple Majority
        
        if (req.approvalCount < threshold) revert Recovery_InsufficientVotes();

        // --- CORE LOGIC: Override Soulbound Ownership ---
        LibIdentityStorage.Layout storage ids = LibIdentityStorage.layout();
        address oldOwner = ids._tokenIdToAddress[_tokenId];
        address newOwner = req.newOwnerAddress;

        // Validasi New Owner tidak punya ID
        if (ids._addressToTokenId[newOwner] != 0) revert Recovery_NewOwnerHasIdentity();

        // 1. Update Mapping Address -> ID
        delete ids._addressToTokenId[oldOwner];
        ids._addressToTokenId[newOwner] = _tokenId;

        // 2. Update Mapping ID -> Address
        ids._tokenIdToAddress[_tokenId] = newOwner;

        // 3. Pindahkan Balance
        ids._balances[oldOwner]--;
        ids._balances[newOwner]++;

        // 4. Reset Request
        req.executed = true;

        emit RecoveryExecuted(_tokenId, oldOwner, newOwner);
    }
}
