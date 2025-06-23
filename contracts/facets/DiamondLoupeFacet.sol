// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {LibDiamond} from "../diamond/libraries/LibDiamond.sol";
import {IDiamondLoupe} from "../interfaces/IDiamondLoupe.sol";

contract DiamondLoupeFacet is IDiamondLoupe {

    function facets() external view override returns (Facet[] memory facets_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 numSelectors = ds.selectors.length;
        address[] memory tempFacetAddresses = new address[](numSelectors);
        uint256 numUniqueFacets = 0;

        for (uint256 i = 0; i < numSelectors; i++) {
            address currentFacetAddress = ds.facetAddress[ds.selectors[i]];
            bool found = false;
            for (uint256 j = 0; j < numUniqueFacets; j++) {
                if (tempFacetAddresses[j] == currentFacetAddress) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                tempFacetAddresses[numUniqueFacets] = currentFacetAddress;
                numUniqueFacets++;
            }
        }

        facets_ = new Facet[](numUniqueFacets);
        for (uint256 i = 0; i < numUniqueFacets; i++) {
            address facetAddr = tempFacetAddresses[i];
            facets_[i].facetAddress = facetAddr;
            facets_[i].functionSelectors = facetFunctionSelectors(facetAddr);
        }
    }

    function facetFunctionSelectors(address _facet) public view override returns (bytes4[] memory _facetFunctionSelectors) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 selectorCount = 0;
        for (uint256 i = 0; i < ds.selectors.length; i++) {
            if (ds.facetAddress[ds.selectors[i]] == _facet) {
                selectorCount++;
            }
        }
        _facetFunctionSelectors = new bytes4[](selectorCount);
        uint256 currentSelectorIndex = 0;
        for (uint256 i = 0; i < ds.selectors.length; i++) {
            if (ds.facetAddress[ds.selectors[i]] == _facet) {
                _facetFunctionSelectors[currentSelectorIndex] = ds.selectors[i];
                currentSelectorIndex++;
            }
        }
    }

    function facetAddress(bytes4 _functionSelector) external view override returns (address facetAddress_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetAddress_ = ds.facetAddress[_functionSelector];
    }
    
    function facetAddresses() external view override returns (address[] memory facetAddresses_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        address[] memory tempAddresses = new address[](selectorCount);
        uint256 uniqueCount = 0;
        for (uint256 i = 0; i < selectorCount; i++) {
            address currentAddr = ds.facetAddress[ds.selectors[i]];
            bool found = false;
            for (uint256 j = 0; j < uniqueCount; j++) {
                if (tempAddresses[j] == currentAddr) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                tempAddresses[uniqueCount] = currentAddr;
                uniqueCount++;
            }
        }
        facetAddresses_ = new address[](uniqueCount);
        for(uint256 i = 0; i < uniqueCount; i++){
            facetAddresses_[i] = tempAddresses[i];
        }
    }
}
