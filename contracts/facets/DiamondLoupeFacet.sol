// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { LibDiamond } from "../diamond/libraries/LibDiamond.sol";

/// @title DiamondLoupeFacet
/// @notice Provides functions for introspecting a diamond.
contract DiamondLoupeFacet {
    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facets and their selectors.
    function facets() external view returns (Facet[] memory facets_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 numFacets = 0;
        // First, count unique facet addresses
        mapping(address => bool) seen;
        for (uint256 i = 0; i < ds.selectors.length; i++) {
            // PERBAIKAN: Mengganti nama variabel lokal
            address _facetAddress = address(uint160(uint256(ds.facetAddressAndSelectorPosition[ds.selectors[i]])));
            if (!seen[_facetAddress]) {
                seen[_facetAddress] = true;
                numFacets++;
            }
        }

        facets_ = new Facet[](numFacets);
        mapping(address => uint256) facetIndex;
        uint256 facetCount = 0;

        for (uint256 i = 0; i < ds.selectors.length; i++) {
            bytes4 selector = ds.selectors[i];
            // PERBAIKAN: Mengganti nama variabel lokal
            address _facetAddress = address(uint160(uint256(ds.facetAddressAndSelectorPosition[selector])));
            
            if (facetIndex[_facetAddress] == 0 && _facetAddress != address(this)) {
                // New facet found, add it to our list
                facetIndex[_facetAddress] = facetCount + 1; // Use 1-based index to distinguish from 0
                facets_[facetCount].facetAddress = _facetAddress;
                facets_[facetCount].functionSelectors = new bytes4[](ds.selectors.length);
                facetCount++;
            }
        }
        
        // Populate the function selectors
        uint256[] memory counts = new uint256[](facetCount);
        for(uint256 i = 0; i < ds.selectors.length; i++) {
            bytes4 selector = ds.selectors[i];
            // PERBAIKAN: Mengganti nama variabel lokal
            address _facetAddress = address(uint160(uint256(ds.facetAddressAndSelectorPosition[selector])));
            uint256 index = facetIndex[_facetAddress];
            if (index > 0) {
                facets_[index-1].functionSelectors[counts[index-1]] = selector;
                counts[index-1]++;
            }
        }
        
        // Resize selector arrays
        for(uint256 i = 0; i < facetCount; i++) {
            bytes4[] memory selectors = facets_[i].functionSelectors;
            uint256 count = counts[i];
            assembly {
                mstore(selectors, count)
            }
        }
    }
    
    /// @notice Gets all function selectors for a given facet.
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory _facetFunctionSelectors) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 count = 0;
        for(uint i=0; i < ds.selectors.length; i++) {
            // PERBAIKAN: Mengganti nama variabel lokal
            address _facetAddress = address(uint160(uint256(ds.facetAddressAndSelectorPosition[ds.selectors[i]])));
            if (_facetAddress == _facet) {
                count++;
            }
        }
        
        _facetFunctionSelectors = new bytes4[](count);
        count = 0;
        for(uint i=0; i < ds.selectors.length; i++) {
            // PERBAIKAN: Mengganti nama variabel lokal
            address _facetAddress = address(uint160(uint256(ds.facetAddressAndSelectorPosition[ds.selectors[i]])));
            if (_facetAddress == _facet) {
                _facetFunctionSelectors[count] = ds.selectors[i];
                count++;
            }
        }
    }

    /// @notice Get the facet address for a given function selector.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetAddress_ = address(uint160(uint256(ds.facetAddressAndSelectorPosition[_functionSelector])));
    }
}
