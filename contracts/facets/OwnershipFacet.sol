// contracts/facets/OwnershipFacet.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { LibDiamond } from "../diamond/libraries/LibDiamond.sol";

contract OwnershipFacet {
    function owner() external view returns (address owner_) {
        owner_ = LibDiamond.diamondStorage().contractOwner;
    }

    function transferOwnership(address _newOwner) external {
        // --- PERBAIKAN: Memanggil fungsi internal untuk cek owner ---
        LibDiamond.enforceIsOwner();
        
        require(_newOwner != address(0), "Ownership: New owner is the zero address");
        LibDiamond.diamondStorage().contractOwner = _newOwner;
    }
}
