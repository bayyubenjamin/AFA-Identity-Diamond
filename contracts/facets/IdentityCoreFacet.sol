// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../libraries/DiamondStorage.sol";
import "../interfaces/IERC721.sol";

contract IdentityCoreFacet is IERC721 {
    AppStorage internal s;

    // --- ERC721 View Functions ---
    function name() external pure returns (string memory) {
        return "AFA Identity";
    }

    function symbol() external pure returns (string memory) {
        return "AFAID";
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = s._tokenIdToAddress[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }
    
    // --- Metadata Logic ---
    // This function will be called by marketplaces like OpenSea.
    // It constructs a URL pointing to your backend (e.g., https://api.yourproject.com/metadata/1)
    // Your backend will then dynamically generate the JSON with the global image and unique traits.
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(s._tokenIdToAddress[tokenId] != address(0), "ERC721URIStorage: URI query for nonexistent token");
        string memory currentBaseURI = s.baseURI;
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, Strings.toString(tokenId)))
            : "";
    }

    // --- Admin Function ---
    function setBaseURI(string memory _newBaseURI) external {
        require(msg.sender == s.contractOwner, "AFA: Must be admin");
        s.baseURI = _newBaseURI;
    }
    
    // --- Soulbound Logic ---
    // Transfers are disabled by not implementing transfer functions like transferFrom, safeTransferFrom.
    // The internal _mint and _burn functions will be handled by the SubscriptionManagerFacet.
    
    // Implementation of other required ERC721 and ERC165 functions...
}
