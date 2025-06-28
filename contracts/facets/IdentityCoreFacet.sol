// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../libraries/LibIdentityStorage.sol";
import "../interfaces/IDiamondLoupe.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract IdentityCoreFacet is IERC721Metadata {
    using LibIdentityStorage for LibIdentityStorage.Layout;


    function name() external pure override returns (string memory) {
        return "AFA Identity";
    }

    function symbol() external pure override returns (string memory) {
        return "AFAID";
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = LibIdentityStorage.layout()._tokenIdToAddress[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return LibIdentityStorage.layout()._balances[owner];
    }

    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        require(s._tokenIdToAddress[tokenId] != address(0), "ERC721: URI query for nonexistent token");
        return bytes(s.baseURI).length > 0
            ? string(abi.encodePacked(s.baseURI, Strings.toString(tokenId)))
            : "";
    }


    function approve(address, uint256) external pure override {
        revert("AFA: Soulbound token cannot be approved");
    }

    function getApproved(uint256) external pure override returns (address) {
        return address(0);
    }

    function setApprovalForAll(address, bool) external pure override {
        revert("AFA: Soulbound token cannot be approved for all");
    }

    function isApprovedForAll(address, address) external pure override returns (bool) {
        return false;
    }

    function transferFrom(address, address, uint256) external pure override {
        revert("AFA: Soulbound token cannot be transferred");
    }

    function safeTransferFrom(address, address, uint256) external pure override {
        revert("AFA: Soulbound token cannot be transferred");
    }

    function safeTransferFrom(address, address, uint256, bytes calldata) external pure override {
        revert("AFA: Soulbound token cannot be transferred");
    }


    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IDiamondLoupe).interfaceId;
    }

    function initialize(address verifier_, string memory _baseURI) external {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();
        require(s.verifierAddress == address(0), "Already initialized");
        s.verifierAddress = verifier_;
        s.baseURI = _baseURI;
    }


    function mintIdentity(bytes calldata _signature) external payable {
        LibIdentityStorage.Layout storage s = LibIdentityStorage.layout();

        bytes32 messageHash = keccak256(abi.encodePacked("AFA_MINT:", msg.sender, s.nonce[msg.sender]));

        address signer = ECDSA.recover(messageHash, _signature);

        require(signer == s.verifierAddress, "AFA: Invalid signature");

        address recipient = msg.sender;
        require(s._addressToTokenId[recipient] == 0, "AFA: Address already has an identity");

        s.nonce[msg.sender]++;

        uint256 tokenId = s._mint(recipient);
        emit Transfer(address(0), recipient, tokenId);
    }
    
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
}
