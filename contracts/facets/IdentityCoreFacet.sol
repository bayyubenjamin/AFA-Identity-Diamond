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

    // Errors
    error Identity_SoulboundTokenCannotBeTransferred();
    error Identity_AlreadyHasIdentity();
    error Identity_InvalidSignature();
    error Identity_NonExistentToken();
    error Identity_QueryForZeroAddress();
    error Identity_NotTokenOwner();
    error Identity_AlreadyInitialized();
    error Identity_CallerNotOwnerOrApproved();

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
        s._mint(recipient);
    }
    
    function burnIdentity(uint256 tokenId) external {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        address owner = s._tokenIdToAddress[tokenId];
        
        if (owner != msg.sender && msg.sender != LibDiamond.contractOwner()) {
             revert Identity_CallerNotOwnerOrApproved();
        }
        
        delete s._tokenIdToAddress[tokenId];
        delete s._addressToTokenId[owner];
        s._balances[owner] -= 1;
        // Emit standard transfer event to 0x0 implies burn logic visualization
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
    
    function setBaseURI(string memory _newBaseURI) external {
        LibDiamond.enforceIsOwner();
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        s.baseURI = _newBaseURI;
    }
}
