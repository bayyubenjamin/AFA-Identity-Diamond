// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../libraries/LibIdentityStorage.sol";
import "../diamond/libraries/LibDiamond.sol";
import "../interfaces/IDiamondLoupe.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract IdentityCoreFacet is IERC721Metadata, EIP712 {
    using LibIdentityStorage for LibIdentityStorage.Layout;
    using Strings for uint256;
    using ECDSA for bytes32;

    bytes32 private constant MINT_TYPEHASH = keccak256("MintIdentity(address recipient,uint256 nonce)");

    // --- Events ---
    // [ADDED] Event untuk tracking perubahan verifier
    event VerifierUpdated(address indexed oldVerifier, address indexed newVerifier);

    // --- Errors ---
    error Identity_SoulboundTokenCannotBeTransferred();
    error Identity_AlreadyHasIdentity();
    error Identity_InvalidSignature();
    error Identity_NonExistentToken();
    error Identity_QueryForZeroAddress();
    error Identity_NotTokenOwner();
    error Identity_AlreadyInitialized();
    error Identity_CallerNotOwnerOrApproved();
    error Identity_InvalidVerifierAddress(); // [ADDED] Error baru jika address 0

    // Constructor EIP712
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

    // --- Soulbound Enforcement ---

    function approve(address, uint256) external pure override { revert Identity_SoulboundTokenCannotBeTransferred(); }
    function getApproved(uint256) external pure override returns (address) { return address(0); }
    function setApprovalForAll(address, bool) external pure override { revert Identity_SoulboundTokenCannotBeTransferred(); }
    function isApprovedForAll(address, address) external pure override returns (bool) { return false; }
    function transferFrom(address, address, uint256) external pure override { revert Identity_SoulboundTokenCannotBeTransferred(); }
    function safeTransferFrom(address, address, uint256) external pure override { revert Identity_SoulboundTokenCannotBeTransferred(); }
    function safeTransferFrom(address, address, uint256, bytes calldata) external pure override { revert Identity_SoulboundTokenCannotBeTransferred(); }

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

    function mintIdentity(bytes calldata _signature) external payable {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        address recipient = msg.sender;

        if (s._addressToTokenId[recipient] != 0) revert Identity_AlreadyHasIdentity();
        
        bytes32 structHash = keccak256(abi.encode(
            MINT_TYPEHASH,
            recipient,
            s.nonce[recipient]
        ));
        
        bytes32 digest = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(digest, _signature);

        if (signer != s.verifierAddress) revert Identity_InvalidSignature();

        s.nonce[recipient]++;
        // Internal mint logic (assuming _mint follows checks-effects-interactions if implemented completely in storage lib)
        // Disini saya asumsikan s._mint adalah helper function di LibIdentityStorage atau dilogikakan manual
        // Karena kode asli LibIdentityStorage tidak memiliki _mint, kita manual set:
        
        // Logika Mint Manual (sesuai best practice storage layout):
        uint256 newTokenId = uint256(uint160(recipient)); // TokenID based on address
        s._tokenIdToAddress[newTokenId] = recipient;
        s._addressToTokenId[recipient] = newTokenId;
        s._balances[recipient] = 1;
        
        // Emit Transfer event (required by ERC721)
        emit Transfer(address(0), recipient, newTokenId);
    }
    
    function burnIdentity(uint256 tokenId) external {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        address owner = s._tokenIdToAddress[tokenId];
        
        // Hanya Owner Token atau Contract Owner (Admin) yang bisa burn
        if (owner != msg.sender && msg.sender != LibDiamond.contractOwner()) {
             revert Identity_CallerNotOwnerOrApproved();
        }
        
        delete s._tokenIdToAddress[tokenId];
        delete s._addressToTokenId[owner];
        s._balances[owner] -= 1;
        
        emit Transfer(owner, address(0), tokenId);
    }

    // --- Governance & Admin Functions ---

    /**
     * @notice Mengubah alamat Verifier (Signer) untuk rotasi key keamanan.
     * @param _newVerifier Alamat signer baru untuk EIP-712.
     */
    function setVerifier(address _newVerifier) external {
        // 1. Keamanan: Hanya Owner Diamond yang bisa panggil
        LibDiamond.enforceIsOwner();

        // 2. Validasi: Mencegah set ke address 0 yang akan mematikan minting
        if (_newVerifier == address(0)) revert Identity_InvalidVerifierAddress();

        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        address oldVerifier = s.verifierAddress;

        // 3. Update State
        s.verifierAddress = _newVerifier;

        // 4. Emit Event
        emit VerifierUpdated(oldVerifier, _newVerifier);
    }
    
    function setBaseURI(string memory _newBaseURI) external {
        LibDiamond.enforceIsOwner();
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        s.baseURI = _newBaseURI;
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

    function exists(uint256 tokenId) external view returns (bool) {
         return LibIdentityStorage.layout()._tokenIdToAddress[tokenId] != address(0);
    }

    function verifier() external view returns (address) {
        return LibIdentityStorage.layout().verifierAddress;
    }
}
