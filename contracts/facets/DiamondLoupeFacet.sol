// contracts/facets/DiamondLoupeFacet.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { LibDiamond } from "../diamond/libraries/LibDiamond.sol";

contract DiamondLoupeFacet {
    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    function facets() external view returns (Facet[] memory facets_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 numSelectors = ds.selectors.length;
        
        address[] memory uniqueFacetAddresses = new address[](numSelectors);
        uint256 numUniqueFacets = 0;

        for (uint256 i = 0; i < numSelectors; i++) {
            // --- PERBAIKAN: Mengganti nama variabel lokal ---
            address currentFacetAddress = address(uint160(uint256(ds.facetAddressAndSelectorPosition[ds.selectors[i]])));
            bool found = false;
            for (uint256 j = 0; j < numUniqueFacets; j++) {
                if (uniqueFacetAddresses[j] == currentFacetAddress) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                uniqueFacetAddresses[numUniqueFacets] = currentFacetAddress;
                numUniqueFacets++;
            }
        }

        facets_ = new Facet[](numUniqueFacets);
        for (uint256 i = 0; i < numUniqueFacets; i++) {
            // --- PERBAIKAN: Mengganti nama variabel lokal ---
            address currentFacetAddress = uniqueFacetAddresses[i];
            bytes4[] memory selectors = facetFunctionSelectors(currentFacetAddress);
            facets_[i] = Facet(currentFacetAddress, selectors);
        }
    }

    function facetFunctionSelectors(address _facet) public view returns (bytes4[] memory _facetFunctionSelectors) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 selectorCount = 0;
        for (uint256 i = 0; i < ds.selectors.length; i++) {
            if (address(uint160(uint256(ds.facetAddressAndSelectorPosition[ds.selectors[i]]))) == _facet) {
                selectorCount++;
            }
        }

        _facetFunctionSelectors = new bytes4[](selectorCount);
        uint256 currentSelectorIndex = 0;
        for (uint256 i = 0; i < ds.selectors.length; i++) {
            if (address(uint160(uint256(ds.facetAddressAndSelectorPosition[ds.selectors[i]]))) == _facet) {
                _facetFunctionSelectors[currentSelectorIndex] = ds.selectors[i];
                currentSelectorIndex++;
            }
        }
    }

    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetAddress_ = address(uint160(uint256(ds.facetAddressAndSelectorPosition[_functionSelector])));
    }
}
