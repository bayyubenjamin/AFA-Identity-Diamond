// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @notice A descriptive name for a collection of NFTs in this contract
     */
    function name() external view returns (string memory _name);

    /**
     * @notice An abbreviated name for NFTs in this contract
     */
    function symbol() external view returns (string memory _symbol);

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given asset.
     * @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
     * 3986. The URI may point to a JSON file that conforms to the "ERC721
     * Metadata JSON Schema".
     */
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}
