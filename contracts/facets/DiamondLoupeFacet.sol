// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { LibDiamond } from "../diamond/libraries/LibDiamond.sol";
import { IDiamondLoupe } from "../interfaces/IDiamondLoupe.sol";
import { IERC165 } from "../interfaces/IERC165.sol";

/// @title Diamond Loupe Facet
/// @notice Standar EIP-2535 untuk introspeksi (melihat fungsi apa saja yang ada di Diamond)
contract DiamondLoupeFacet is IDiamondLoupe, IERC165 {
    
    // --- ERC165 Support ---

    /// @notice Mengecek apakah kontrak mendukung interface tertentu
    function supportsInterface(bytes4 _interfaceId) external view override returns (bool) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.supportedInterfaces[_interfaceId];
    }

    // --- Loupe Functions ---

    /// @notice Mendapatkan semua facets dan selector fungsinya
    function facets() external view override returns (Facet[] memory facets_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 numSelectors = ds.selectors.length;
        
        // Array temp untuk menyimpan facet address unik
        address[] memory tempFacetAddresses = new address[](numSelectors);
        uint256 numUniqueFacets = 0;

        // Loop 1: Cari semua facet address unik
        for (uint256 i = 0; i < numSelectors; ) {
            address currentFacetAddress = ds.facetAddress[ds.selectors[i]];
            bool found = false;
            for (uint256 j = 0; j < numUniqueFacets; ) {
                if (tempFacetAddresses[j] == currentFacetAddress) {
                    found = true;
                    break;
                }
                unchecked { j++; }
            }
            if (!found) {
                tempFacetAddresses[numUniqueFacets] = currentFacetAddress;
                numUniqueFacets++;
            }
            unchecked { i++; }
        }

        facets_ = new Facet[](numUniqueFacets);

        // Loop 2: Populate struct Facet untuk setiap address unik
        for (uint256 i = 0; i < numUniqueFacets; ) {
            address facetAddr = tempFacetAddresses[i];
            facets_[i].facetAddress = facetAddr;
            facets_[i].functionSelectors = _getSelectorsForFacet(ds, facetAddr);
            unchecked { i++; }
        }
    }

    /// @notice Mendapatkan semua function selector untuk facet tertentu
    function facetFunctionSelectors(address _facet) external view override returns (bytes4[] memory) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return _getSelectorsForFacet(ds, _facet);
    }

    /// @notice Mendapatkan semua address facet yang digunakan oleh diamond ini
    function facetAddresses() external view override returns (address[] memory facetAddresses_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 numSelectors = ds.selectors.length;
        
        address[] memory tempAddresses = new address[](numSelectors);
        uint256 uniqueCount = 0;

        for (uint256 i = 0; i < numSelectors; ) {
            address currentAddr = ds.facetAddress[ds.selectors[i]];
            bool found = false;
            for (uint256 j = 0; j < uniqueCount; ) {
                if (tempAddresses[j] == currentAddr) {
                    found = true;
                    break;
                }
                unchecked { j++; }
            }
            if (!found) {
                tempAddresses[uniqueCount] = currentAddr;
                uniqueCount++;
            }
            unchecked { i++; }
        }

        // Resize array ke ukuran yang pas (uniqueCount)
        facetAddresses_ = new address[](uniqueCount);
        for (uint256 i = 0; i < uniqueCount; ) {
            facetAddresses_[i] = tempAddresses[i];
            unchecked { i++; }
        }
    }

    /// @notice Mendapatkan address facet untuk selector tertentu
    function facetAddress(bytes4 _functionSelector) external view override returns (address facetAddress_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetAddress_ = ds.facetAddress[_functionSelector];
    }

    // --- Private Helpers ---

    /// @dev Helper private untuk menghindari duplikasi kode di facetFunctionSelectors dan facets
    function _getSelectorsForFacet(LibDiamond.DiamondStorage storage ds, address _facet) private view returns (bytes4[] memory _facetFunctionSelectors) {
        uint256 numSelectors = ds.selectors.length;
        uint256 selectorCount = 0;

        // Pass 1: Hitung jumlah selector milik facet ini
        for (uint256 i = 0; i < numSelectors; ) {
            if (ds.facetAddress[ds.selectors[i]] == _facet) {
                selectorCount++;
            }
            unchecked { i++; }
        }

        // Pass 2: Isi array
        _facetFunctionSelectors = new bytes4[](selectorCount);
        uint256 currentSelectorIndex = 0;
        for (uint256 i = 0; i < numSelectors; ) {
            if (ds.facetAddress[ds.selectors[i]] == _facet) {
                _facetFunctionSelectors[currentSelectorIndex] = ds.selectors[i];
                currentSelectorIndex++;
            }
            unchecked { i++; }
        }
    }
}
