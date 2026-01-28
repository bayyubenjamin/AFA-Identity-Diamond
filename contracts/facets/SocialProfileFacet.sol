// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { LibSocialStorage } from "../libraries/LibSocialStorage.sol";
import { LibIdentityStorage } from "../libraries/LibIdentityStorage.sol";
import { LibDiamond } from "../diamond/libraries/LibDiamond.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Internal Storage untuk Social Graph (Extension) ---
library LibSocialGraphStorage {
    bytes32 constant STORAGE_POSITION = keccak256("afa.identity.socialgraph.storage.v1");
    struct Layout {
        // User A follows User B? [A][B] => bool
        mapping(uint256 => mapping(uint256 => bool)) isFollowing;
        // Jumlah pengikut & yang diikuti
        mapping(uint256 => uint256) followerCount;
        mapping(uint256 => uint256) followingCount;
    }
    function layout() internal pure returns (Layout storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly { s.slot := position }
    }
}

contract SocialProfileFacet {
    using Strings for uint256;

    event ProfileUpdated(uint256 indexed tokenId, string newHandle);
    event ReputationChanged(uint256 indexed tokenId, uint256 newScore);
    event HandleClaimed(string handle, uint256 indexed tokenId);
    
    // [NEW] Social Events
    event UserFollowed(uint256 indexed followerId, uint256 indexed followedId);
    event UserUnfollowed(uint256 indexed followerId, uint256 indexed followedId);

    error Social_OnlyIdentityOwner();
    error Social_HandleAlreadyTaken();
    error Social_HandleInvalidLength();
    error Social_IdentityNotFound();
    error Social_Unauthorized();
    error Social_CannotFollowSelf();
    error Social_AlreadyFollowing();
    error Social_NotFollowing();

    modifier onlyIdentityOwner() {
        LibIdentityStorage.Layout storage ids = LibIdentityStorage.layout();
        uint256 tokenId = ids._addressToTokenId[msg.sender];
        if (tokenId == 0) revert Social_IdentityNotFound();
        if (ids._tokenIdToAddress[tokenId] != msg.sender) revert Social_OnlyIdentityOwner();
        _;
    }

    modifier onlyAdmin() {
        LibDiamond.enforceIsOwner();
        _;
    }

    // --- Profile Logic ---

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

        if (keccak256(bytes(profile.handle)) != keccak256(bytes(_handle))) {
            _validateHandle(_handle);
            if (bytes(profile.handle).length > 0) {
                delete ss.handleToTokenId[profile.handle];
            }
            if (ss.handleToTokenId[_handle] != 0) revert Social_HandleAlreadyTaken();
            ss.handleToTokenId[_handle] = tokenId;
            emit HandleClaimed(_handle, tokenId);
        }

        profile.handle = _handle;
        profile.displayName = _displayName;
        profile.bio = _bio;
        profile.avatarURI = _avatarURI;
        profile.externalLink = _externalLink;
        profile.isPublic = _isPublic;
        profile.initialized = true;

        emit ProfileUpdated(tokenId, _handle);
    }

    // --- Social Graph Logic (Follow System) ---

    function follow(uint256 _targetTokenId) external onlyIdentityOwner {
        LibIdentityStorage.Layout storage ids = LibIdentityStorage.layout();
        LibSocialGraphStorage.Layout storage sg = LibSocialGraphStorage.layout();
        
        uint256 myTokenId = ids._addressToTokenId[msg.sender];

        if (myTokenId == _targetTokenId) revert Social_CannotFollowSelf();
        if (ids._tokenIdToAddress[_targetTokenId] == address(0)) revert Social_IdentityNotFound();
        if (sg.isFollowing[myTokenId][_targetTokenId]) revert Social_AlreadyFollowing();

        sg.isFollowing[myTokenId][_targetTokenId] = true;
        sg.followingCount[myTokenId]++;
        sg.followerCount[_targetTokenId]++;

        emit UserFollowed(myTokenId, _targetTokenId);
    }

    function unfollow(uint256 _targetTokenId) external onlyIdentityOwner {
        LibIdentityStorage.Layout storage ids = LibIdentityStorage.layout();
        LibSocialGraphStorage.Layout storage sg = LibSocialGraphStorage.layout();
        
        uint256 myTokenId = ids._addressToTokenId[msg.sender];

        if (!sg.isFollowing[myTokenId][_targetTokenId]) revert Social_NotFollowing();

        sg.isFollowing[myTokenId][_targetTokenId] = false;
        sg.followingCount[myTokenId]--;
        sg.followerCount[_targetTokenId]--;

        emit UserUnfollowed(myTokenId, _targetTokenId);
    }

    // --- Admin & Config ---

    function setReputation(uint256 _tokenId, uint256 _score) external onlyAdmin {
        LibSocialStorage.layout().profiles[_tokenId].reputationScore = _score;
        emit ReputationChanged(_tokenId, _score);
    }

    function setHandleConfig(uint256 _min, uint256 _max) external onlyAdmin {
        LibSocialStorage.Layout storage ss = LibSocialStorage.layout();
        ss.minHandleLength = _min;
        ss.maxHandleLength = _max;
    }

    function setPrivacy(bool _isPublic) external onlyIdentityOwner {
        LibIdentityStorage.Layout storage ids = LibIdentityStorage.layout();
        uint256 tokenId = ids._addressToTokenId[msg.sender];
        LibSocialStorage.layout().profiles[tokenId].isPublic = _isPublic;
    }

    // --- View Functions ---

    function getProfile(uint256 _tokenId) external view returns (LibSocialStorage.Profile memory) {
        return LibSocialStorage.layout().profiles[_tokenId];
    }

    function getSocialStats(uint256 _tokenId) external view returns (uint256 followers, uint256 following) {
        LibSocialGraphStorage.Layout storage sg = LibSocialGraphStorage.layout();
        return (sg.followerCount[_tokenId], sg.followingCount[_tokenId]);
    }

    function isFollowing(uint256 _follower, uint256 _followed) external view returns (bool) {
        return LibSocialGraphStorage.layout().isFollowing[_follower][_followed];
    }

    function getProfileByHandle(string calldata _handle) external view returns (LibSocialStorage.Profile memory) {
        uint256 tokenId = LibSocialStorage.layout().handleToTokenId[_handle];
        if (tokenId == 0) revert Social_IdentityNotFound();
        return LibSocialStorage.layout().profiles[tokenId];
    }

    function isHandleTaken(string calldata _handle) external view returns (bool) {
        return LibSocialStorage.layout().handleToTokenId[_handle] != 0;
    }

    function _validateHandle(string memory _handle) internal view {
        bytes memory h = bytes(_handle);
        LibSocialStorage.Layout storage ss = LibSocialStorage.layout();
        uint256 min = ss.minHandleLength == 0 ? 3 : ss.minHandleLength;
        uint256 max = ss.maxHandleLength == 0 ? 15 : ss.maxHandleLength;
        if (h.length < min || h.length > max) revert Social_HandleInvalidLength();
        for(uint i; i < h.length; i++){
            bytes1 char = h[i];
            if(!(char >= 0x30 && char <= 0x39) && !(char >= 0x61 && char <= 0x7A) && !(char == 0x5F)) {
                revert("Invalid characters in handle");
            }
        }
    }
}
