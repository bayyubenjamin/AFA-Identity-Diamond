// contracts/facets/OwnershipFacet.sol (FINAL CORRECTED VERSION)

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { LibDiamond } from "../diamond/libraries/LibDiamond.sol";

contract OwnershipFacet {
    function owner() external view returns (address owner_) {
        owner_ = LibDiamond.diamondStorage().contractOwner;
    }

    function transferOwnership(address _newOwner) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(msg.sender == ds.contractOwner, "OwnershipFacet: Must be contract owner");
        
        require(_newOwner != address(0), "Ownership: New owner is the zero address");
        ds.contractOwner = _newOwner;
    }

    // --- FUNGSI DENGAN PERBAIKAN ---
    // Fungsi ini memungkinkan owner untuk menarik seluruh saldo ETH dari kontrak Diamond.
    function withdraw() external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        // Memastikan hanya owner yang bisa memanggil fungsi ini
        require(msg.sender == ds.contractOwner, "OwnershipFacet: Must be contract owner");
        
        // PERBAIKAN: Menggunakan .call() yang lebih aman dan direkomendasikan daripada .transfer()
        (bool success, ) = ds.contractOwner.call{value: address(this).balance}("");
        require(success, "Withdrawal: ETH transfer failed");
    }
}
