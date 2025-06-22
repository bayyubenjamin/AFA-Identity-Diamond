// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { LibDiamond } from "./libraries/LibDiamond.sol";

/// @title Diamond
/// @notice The main proxy contract for the Diamond Standard (EIP-2535).
/// It delegates all calls to the appropriate facet.
contract Diamond {
    constructor(address _contractOwner) payable {
        LibDiamond.diamondStorage().contractOwner = _contractOwner;
    }

    /// @notice The fallback function is the heart of the diamond. It delegates calls
    /// to the correct facet using `delegatecall`.
    fallback() external payable {
        bytes32 facetAddressAndSelectorPosition = LibDiamond.diamondStorage().facetAddressAndSelectorPosition[msg.sig];
        
        // Extract the facet address (first 20 bytes of the 32-byte slot)
        address facetAddress = address(uint160(uint256(facetAddressAndSelectorPosition)));
        
        require(facetAddress != address(0), "Diamond: Function does not exist");

        assembly {
            // Copy msg.data to memory
            calldatacopy(0, 0, calldatasize())
            // Execute the function from the facet using delegatecall
            let result := delegatecall(gas(), facetAddress, 0, calldatasize(), 0, 0)
            // Copy the return data
            returndatacopy(0, 0, returndatasize())
            // Revert if the call failed, otherwise return the result
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}
