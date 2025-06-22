// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { LibDiamond } from "../diamond/libraries/LibDiamond.sol";

/// @title OwnershipFacet
/// @notice Manages the ownership of the diamond contract.
contract OwnershipFacet {
    /// @notice Returns the owner of the contract.
    function owner() external view returns (address owner_) {
        owner_ = LibDiamond.diamondStorage().contractOwner;
    }

    /// @notice Transfers ownership of the contract to a new owner.
    /// @param _newOwner The address of the new owner.
    function transferOwnership(address _newOwner) external LibDiamond.enforceIsOwner {
        require(_newOwner != address(0), "Ownership: New owner is the zero address");
        LibDiamond.diamondStorage().contractOwner = _newOwner;
    }
}
