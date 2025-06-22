// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { LibDiamond } from "../diamond/libraries/LibDiamond.sol";
import { AppStorage } from "../storage/AppStorage.sol";

contract AFA_Admin_Facet {
    event IdentityMinted(address indexed to, uint256 indexed tokenId, string handle);
    event AdminStatusChanged(address indexed admin, bool indexed isActive);
    event VerificationStatusChanged(uint256 indexed tokenId, bool isVerified);

    modifier onlyOwner() {
        require(msg.sender == LibDiamond.appStorage().contractOwner, "AFA: Must be contract owner");
        _;
    }

    modifier onlyAdmin() {
        require(LibDiamond.appStorage().admins[msg.sender], "AFA: Must be admin");
        _;
    }

    /// @notice Initialize the Diamond storage. Can only be called once.
    function initialize(string memory name, string memory symbol, address initialAdmin) external {
        AppStorage storage s = LibDiamond.appStorage();
        require(s.contractOwner == address(0), "AFA: Already initialized");
        
        s.name = name;
        s.symbol = symbol;
        s.contractOwner = msg.sender;
        s.admins[initialAdmin] = true;
    }

    /// @notice Mint a new AFA Identity NFT.
    function mintIdentity(address to, string memory handle, string memory metadataUri, bytes32 proofHash) external onlyAdmin {
        AppStorage storage s = LibDiamond.appStorage();
        require(to != address(0), "AFA: Cannot mint to zero address");
        require(s.addressToTokenId[to] == 0, "AFA: Address already has an identity");
        require(!s.usedProofHashes[proofHash], "AFA: Proof of human already used");
        // Di sini bisa ditambahkan validasi untuk handle jika mapping `isHandleTaken` sudah dibuat.

        s.usedProofHashes[proofHash] = true;
        
        uint256 tokenId = s.currentTokenId + 1;
        s.currentTokenId = tokenId;
        s.totalSupply += 1;

        // ERC721 State
        s.owners[tokenId] = to;
        s.balances[to] += 1;
        
        // Identity State
        s.addressToTokenId[to] = tokenId;
        s.handle[tokenId] = handle;
        s.identityMetadata[tokenId] = metadataUri;
        s.createdAt[tokenId] = block.timestamp;
        s.isVerified[tokenId] = false; // Verifikasi default adalah false

        emit Transfer(address(0), to, tokenId); // Event standar ERC721
        emit IdentityMinted(to, tokenId, handle);
    }
    
    function setAdmin(address admin, bool isActive) external onlyOwner {
        LibDiamond.appStorage().admins[admin] = isActive;
        emit AdminStatusChanged(admin, isActive);
    }

    function setVerifiedStatus(uint256 tokenId, bool verified) external onlyAdmin {
        require(LibDiamond.appStorage().owners[tokenId] != address(0), "AFA: Token does not exist");
        LibDiamond.appStorage().isVerified[tokenId] = verified;
        emit VerificationStatusChanged(tokenId, verified);
    }

    function updateReputation(uint256 tokenId, uint256 newScore) external onlyAdmin {
        require(LibDiamond.appStorage().owners[tokenId] != address(0), "AFA: Token does not exist");
        LibDiamond.appStorage().reputationScore[tokenId] = newScore;
    }

    // Diperlukan agar event Transfer bisa di-emit dari facet ini
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
}
