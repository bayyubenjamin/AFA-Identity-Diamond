// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../libraries/DiamondStorage.sol";
import "../interfaces/IOwnershipFacet.sol";
import "../interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SubscriptionManagerFacet {
    DiamondStorage internal s;

    event IdentityMinted(address indexed user, uint256 indexed tokenId);
    event SubscriptionRenewed(uint256 indexed tokenId, uint256 newExpiration);

    /**
     * @notice Initializes the diamond with core settings.
     * @dev Can only be called once. The caller of diamondCut becomes the owner.
     * @param _verifierAddress The address of the backend server authorized to sign minting messages.
     * @param _baseURI The base URI for the token metadata.
     */
    function initialize(address _verifierAddress, string memory _baseURI) external {
        require(s.verifierAddress == address(0), "Already initialized");
        s.verifierAddress = _verifierAddress;
        s.baseURI = _baseURI;
    }

    // --- Admin Functions ---
    // NOTE: These functions are placeholders and need full implementation.
    // They should check for ownership using IOwnershipFacet.
    function setPriceInUSD(uint256 _priceInCents) external {
        require(msg.sender == IOwnershipFacet(address(this)).owner(), "AFA: Must be admin");
        s.priceInUSD = _priceInCents;
    }

    // --- Public Mint & Renew Functions ---
    // NOTE: These functions are placeholders and need full implementation.
    function mintIdentity(bytes calldata _signature) external payable {
        // Full implementation will include:
        // 1. Signature verification
        // 2. Payment processing
        // 3. Minting logic (as seen in TestingAdminFacet)
        revert("Not implemented");
    }

    function renewSubscription(uint256 tokenId) external payable {
        // Full implementation will include:
        // 1. Payment processing
        // 2. Updating attestation timestamp
        revert("Not implemented");
    }
}
