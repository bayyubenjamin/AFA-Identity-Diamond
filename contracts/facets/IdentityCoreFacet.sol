// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AppStorage} from "../libraries/DiamondStorage.sol";
import {IDiamondLoupe} from "../interfaces/IDiamondLoupe.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IdentityCoreFacet
 * @notice Mengelola fungsi inti NFT seperti URI dan kepemilikan.
 */
contract IdentityCoreFacet {
    AppStorage internal s;

    /**
     * @dev Ini adalah implementasi standar EIP-165.
     * Menggunakan loupe untuk memeriksa apakah diamond mendukung interfaceId tertentu.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return IERC165(address(this)).supportsInterface(interfaceId);
    }
    
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = s._tokenIdToAddress[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function baseURI() public view returns (string memory) {
        return s.baseURI;
    }
    
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(s._tokenIdToAddress[tokenId] != address(0), "ERC721: URI query for nonexistent token");

        string memory currentBaseURI = baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _toString(tokenId)))
            : "";
    }
    
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
