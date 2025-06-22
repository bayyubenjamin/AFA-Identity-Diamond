// contracts/facets/DiamondCutFacet.sol (Corrected)

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { LibDiamond } from "../diamond/libraries/LibDiamond.sol";

// Definisikan interface agar bisa di-import oleh kontrak lain
interface IDiamondCut {
    function diamondCut(
        LibDiamond.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) external;
}

contract DiamondCutFacet is IDiamondCut {
    function diamondCut(
        LibDiamond.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) external override {
        LibDiamond.enforceIsOwner();

        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        for (uint256 i = 0; i < _diamondCut.length; i++) {
            LibDiamond.Action action = _diamondCut[i].action;
            address facetAddress = _diamondCut[i].facetAddress;
            bytes4[] memory functionSelectors = _diamondCut[i].functionSelectors;

            if (action == LibDiamond.Action.Add) {
                addFunctions(ds, functionSelectors, facetAddress);
            } else if (action == LibDiamond.Action.Replace) {
                replaceFunctions(ds, functionSelectors, facetAddress);
            } else if (action == LibDiamond.Action.Remove) {
                removeFunctions(ds, functionSelectors);
            } else {
                revert("DiamondCut: Incorrect Action");
            }
        }
        
        emit LibDiamond.DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(LibDiamond.DiamondStorage storage ds, bytes4[] memory _functionSelectors, address _facetAddress) private {
        for (uint256 i = 0; i < _functionSelectors.length; i++) {
            bytes4 selector = _functionSelectors[i];
            bytes32 oldFacetAddressAndSelectorPosition = ds.facetAddressAndSelectorPosition[selector];
            require(address(uint160(uint256(oldFacetAddressAndSelectorPosition))) == address(0), "DiamondCut: Can't add function that already exists");
            
            ds.selectors.push(selector);
            uint256 selectorIndex = ds.selectors.length - 1;
            ds.selectorIndices[selector] = selectorIndex;
            ds.facetAddressAndSelectorPosition[selector] = bytes32((uint256(uint160(_facetAddress))) | (selectorIndex << 160));
        }
    }

    function replaceFunctions(LibDiamond.DiamondStorage storage ds, bytes4[] memory _functionSelectors, address _facetAddress) private {
        for (uint256 i = 0; i < _functionSelectors.length; i++) {
            bytes4 selector = _functionSelectors[i];
            bytes32 oldFacetAddressAndSelectorPosition = ds.facetAddressAndSelectorPosition[selector];
            require(address(uint160(uint256(oldFacetAddressAndSelectorPosition))) != address(0), "DiamondCut: Can't replace function that doesn't exist");
            
            uint256 selectorIndex = ds.selectorIndices[selector];
            ds.facetAddressAndSelectorPosition[selector] = bytes32((uint256(uint160(_facetAddress))) | (selectorIndex << 160));
        }
    }

    function removeFunctions(LibDiamond.DiamondStorage storage ds, bytes4[] memory _functionSelectors) private {
        for (uint256 i = 0; i < _functionSelectors.length; i++) {
            bytes4 selector = _functionSelectors[i];
            bytes32 facetAddressAndSelectorPosition = ds.facetAddressAndSelectorPosition[selector];
            require(address(uint160(uint256(facetAddressAndSelectorPosition))) != address(0), "DiamondCut: Can't remove function that doesn't exist");

            uint256 selectorIndex = ds.selectorIndices[selector];
            bytes4 lastSelector = ds.selectors[ds.selectors.length - 1];
            
            if (selector != lastSelector) {
                ds.selectors[selectorIndex] = lastSelector;
                ds.selectorIndices[lastSelector] = selectorIndex;
            }
            ds.selectors.pop();
            delete ds.selectorIndices[selector];
            delete ds.facetAddressAndSelectorPosition[selector];
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) private {
        if (_init != address(0)) {
            (bool success, ) = _init.delegatecall(_calldata);
            require(success, "DiamondCut: _init call failed");
        }
    }
}
