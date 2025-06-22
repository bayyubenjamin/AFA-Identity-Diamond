// contracts/diamond/Diamond.sol (Corrected Version)

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { LibDiamond } from "./libraries/LibDiamond.sol";

// --- INI ADALAH BARIS PENTING YANG MEMPERBAIKI ERROR ---
import { IDiamondCut } from "../facets/DiamondCutFacet.sol";

contract Diamond {
    constructor(address _contractOwner, IDiamondCut.FacetCut[] memory _diamondCut) payable {
        LibDiamond.diamondStorage().contractOwner = _contractOwner;

        // Dapatkan alamat DiamondCutFacet dari data potongan pertama
        address diamondCutFacetAddress = address(0);
        for (uint i = 0; i < _diamondCut.length; i++) {
            // Kita asumsikan DiamondCutFacet ada di dalam initial cut
            if (_diamondCut[i].functionSelectors.length > 0) {
                diamondCutFacetAddress = _diamondCut[i].facetAddress;
                break;
            }
        }
        require(diamondCutFacetAddress != address(0), "Diamond: DiamondCutFacet not found in initial cut");

        // Encode pemanggilan fungsi `diamondCut`
        bytes memory functionCall = abi.encodeWithSelector(
            IDiamondCut.diamondCut.selector,
            _diamondCut,
            address(0),
            ""
        );

        // Lakukan delegatecall untuk menambahkan semua facet awal
        (bool success, ) = diamondCutFacetAddress.delegatecall(functionCall);
        require(success, "Diamond: initial diamond cut failed");
    }

    fallback() external payable {
        bytes32 facetAddressAndSelectorPosition = LibDiamond.diamondStorage().facetAddressAndSelectorPosition[msg.sig];
        
        address facetAddress = address(uint160(uint256(facetAddressAndSelectorPosition)));
        
        require(facetAddress != address(0), "Diamond: Function does not exist");

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facetAddress, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
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
