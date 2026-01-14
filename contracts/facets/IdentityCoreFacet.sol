// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../libraries/LibIdentityStorage.sol";
import "../diamond/libraries/LibDiamond.sol";
import "../interfaces/IDiamondLoupe.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol"; // [NEW] Import EIP712

contract IdentityCoreFacet is IERC721Metadata, EIP712 { // [NEW] Inherit EIP712
    using LibIdentityStorage for LibIdentityStorage.Layout;
    using Strings for uint256;
    using ECDSA for bytes32;

    // --- TypeHash untuk EIP-712 ---
    // Sesuai standar: keccak256("Function(Type arg1,Type arg2...)")
    bytes32 private constant MINT_TYPEHASH = keccak256("MintIdentity(address recipient,uint256 nonce)");

    // --- Custom Errors ---
    error Identity_SoulboundTokenCannotBeTransferred();
    error Identity_AlreadyHasIdentity();
    error Identity_InvalidSignature();
    error Identity_NonExistentToken();
    error Identity_QueryForZeroAddress();
    error Identity_NotTokenOwner();
    error Identity_AlreadyInitialized();

    // [NEW] Constructor EIP712
    // Facet bisa punya constructor untuk set immutable variables di bytecode-nya
    constructor() EIP712("Afa Identity", "1") {}

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
        LibDiamond.enforceIsOwner();
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        if (s.verifierAddress != address(0)) revert Identity_AlreadyInitialized();
        
        s.verifierAddress = verifier_;
        s.baseURI = _baseURI;
    }

    /// @notice Mint Identity dengan EIP-712 Signature
    /// @dev Menggunakan _hashTypedDataV4 untuk keamanan replay attack cross-chain & cross-contract
    function mintIdentity(bytes calldata _signature) external payable {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        address recipient = msg.sender;

        // 1. Cek apakah user sudah punya identity
        if (s._addressToTokenId[recipient] != 0) revert Identity_AlreadyHasIdentity();

        // 2. Buat Hash Struct sesuai EIP-712
        // ChainID dan Contract Address sudah otomatis dihandle oleh _hashTypedDataV4
        bytes32 structHash = keccak256(abi.encode(
            MINT_TYPEHASH,
            recipient,
            s.nonce[recipient]
        ));

        // 3. Hash Final dengan Domain Separator
        bytes32 digest = _hashTypedDataV4(structHash);

        // 4. Recover Signer
        address signer = ECDSA.recover(digest, _signature);

        // 5. Verifikasi
        if (signer != s.verifierAddress) revert Identity_InvalidSignature();

        // 6. Eksekusi
        s.nonce[recipient]++;
        uint256 tokenId = s._mint(recipient);
        
        // Emit event transfer manual karena library storage tidak emit event standard
        // (Opsional: tambahkan emit Transfer(address(0), recipient, tokenId); jika event didefinisikan)
    }
    
    function burnIdentity(uint256 tokenId) external {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        if (s._tokenIdToAddress[tokenId] != msg.sender) revert Identity_NotTokenOwner();
        
        delete s._tokenIdToAddress[tokenId];
        delete s._addressToTokenId[msg.sender];
        s._balances[msg.sender] -= 1;
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
    
    function setBaseURI(string memory _newBaseURI) external {
        LibDiamond.enforceIsOwner();
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        s.baseURI = _newBaseURI;
    }
}
