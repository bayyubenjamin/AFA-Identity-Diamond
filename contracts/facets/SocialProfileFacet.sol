// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { LibSocialStorage } from "../libraries/LibSocialStorage.sol";
import { LibIdentityStorage } from "../libraries/LibIdentityStorage.sol";
import { LibDiamond } from "../diamond/libraries/LibDiamond.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SocialProfileFacet {
    using Strings for uint256;

    // Events
    event ProfileUpdated(uint256 indexed tokenId, string newHandle);
    event ReputationChanged(uint256 indexed tokenId, uint256 newScore);
    event HandleClaimed(string handle, uint256 indexed tokenId);

    // Errors
    error Social_OnlyIdentityOwner();
    error Social_HandleAlreadyTaken();
    error Social_HandleInvalidLength();
    error Social_IdentityNotFound();
    error Social_Unauthorized();

    // --- Modifiers ---

    modifier onlyIdentityOwner() {
        LibIdentityStorage.Layout storage ids = LibIdentityStorage.layout();
        // Cek ID milik msg.sender
        uint256 tokenId = ids._addressToTokenId[msg.sender];
        if (tokenId == 0) revert Social_IdentityNotFound();
        // Double check ownership (redundant but safe)
        if (ids._tokenIdToAddress[tokenId] != msg.sender) revert Social_OnlyIdentityOwner();
        _;
    }

    modifier onlyAdmin() {
        LibDiamond.enforceIsOwner();
        _;
    }

    // --- User Functions (Write) ---

    /// @notice User mengatur profil lengkap mereka
    function setProfile(
        string calldata _handle,
        string calldata _displayName,
        string calldata _bio,
        string calldata _avatarURI,
        string calldata _externalLink,
        bool _isPublic
    ) external onlyIdentityOwner {
        LibSocialStorage.Layout storage ss = LibSocialStorage.layout();
        LibIdentityStorage.Layout storage ids = LibIdentityStorage.layout();
        
        uint256 tokenId = ids._addressToTokenId[msg.sender];
        LibSocialStorage.Profile storage profile = ss.profiles[tokenId];

        // Logika Handle (Username)
        // Jika handle berubah, cek ketersediaan
        if (keccak256(bytes(profile.handle)) != keccak256(bytes(_handle))) {
            _validateHandle(_handle);
            
            // Hapus handle lama dari mapping jika ada
            if (bytes(profile.handle).length > 0) {
                delete ss.handleToTokenId[profile.handle];
            }

            // Cek handle baru
            if (ss.handleToTokenId[_handle] != 0) revert Social_HandleAlreadyTaken();
            
            // Simpan handle baru
            ss.handleToTokenId[_handle] = tokenId;
            emit HandleClaimed(_handle, tokenId);
        }

        // Update Data
        profile.handle = _handle;
        profile.displayName = _displayName;
        profile.bio = _bio;
        profile.avatarURI = _avatarURI;
        profile.externalLink = _externalLink;
        profile.isPublic = _isPublic;
        profile.initialized = true;

        emit ProfileUpdated(tokenId, _handle);
    }

    /// @notice Toggle status publik profil
    function setPrivacy(bool _isPublic) external onlyIdentityOwner {
        LibIdentityStorage.Layout storage ids = LibIdentityStorage.layout();
        uint256 tokenId = ids._addressToTokenId[msg.sender];
        
        LibSocialStorage.layout().profiles[tokenId].isPublic = _isPublic;
    }

    // --- Admin Functions ---

    /// @notice Admin memberikan skor reputasi (bisa disambungkan ke logic off-chain)
    function setReputation(uint256 _tokenId, uint256 _score) external onlyAdmin {
        LibSocialStorage.layout().profiles[_tokenId].reputationScore = _score;
        emit ReputationChanged(_tokenId, _score);
    }

    function setHandleConfig(uint256 _min, uint256 _max) external onlyAdmin {
        LibSocialStorage.Layout storage ss = LibSocialStorage.layout();
        ss.minHandleLength = _min;
        ss.maxHandleLength = _max;
    }

    // --- View Functions ---

    function getProfile(uint256 _tokenId) external view returns (LibSocialStorage.Profile memory) {
        return LibSocialStorage.layout().profiles[_tokenId];
    }

    function getProfileByHandle(string calldata _handle) external view returns (LibSocialStorage.Profile memory) {
        uint256 tokenId = LibSocialStorage.layout().handleToTokenId[_handle];
        if (tokenId == 0) revert Social_IdentityNotFound();
        return LibSocialStorage.layout().profiles[tokenId];
    }

    function isHandleTaken(string calldata _handle) external view returns (bool) {
        return LibSocialStorage.layout().handleToTokenId[_handle] != 0;
    }

    // --- Internal Helpers ---

    function _validateHandle(string memory _handle) internal view {
        bytes memory h = bytes(_handle);
        LibSocialStorage.Layout storage ss = LibSocialStorage.layout();
        
        // Default config jika belum diset admin
        uint256 min = ss.minHandleLength == 0 ? 3 : ss.minHandleLength;
        uint256 max = ss.maxHandleLength == 0 ? 15 : ss.maxHandleLength;

        if (h.length < min || h.length > max) revert Social_HandleInvalidLength();

        // Validasi karakter (hanya a-z, 0-9, _)
        for(uint i; i < h.length; i++){
            bytes1 char = h[i];
            if(
                !(char >= 0x30 && char <= 0x39) && // 0-9
                !(char >= 0x61 && char <= 0x7A) && // a-z
                !(char == 0x5F) // _
            ) {
                revert("Invalid characters in handle");
            }
        }
    }
}
