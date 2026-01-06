// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { LibDiamond } from "../diamond/libraries/LibDiamond.sol";
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

contract DiamondCutFacet is IDiamondCut {
    // --- Custom Errors (Gas Efficient) ---
    error IncorrectFacetCutAction(FacetCutAction action);
    error InitCallFailed();
    error FacetAddressIsZero();
    error FacetAddressIsNotZero();
    error FunctionAlreadyExists(bytes4 selector);
    error FunctionDoesNotExist(bytes4 selector);
    error FunctionIsImmutable(bytes4 selector);
    error CannotRemoveFunctionThatDoesNotExist(bytes4 selector);
    error CannotRemoveImmutableFunction(bytes4 selector);

    // --- External Function ---

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {
        LibDiamond.enforceIsOwner();

        for (uint256 i; i < _diamondCut.length; i++) {
            FacetCutAction action = _diamondCut[i].action;
            address facetAddress = _diamondCut[i].facetAddress;
            bytes4[] memory functionSelectors = _diamondCut[i].functionSelectors;

            if (action == FacetCutAction.Add) {
                addFunctions(facetAddress, functionSelectors);
            } else if (action == FacetCutAction.Replace) {
                replaceFunctions(facetAddress, functionSelectors);
            } else if (action == FacetCutAction.Remove) {
                removeFunctions(facetAddress, functionSelectors);
            } else {
                revert IncorrectFacetCutAction(action);
            }
        }

        emit LibDiamond.DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    // --- Internal Logic ---

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) private {
        if (_facetAddress == address(0)) revert FacetAddressIsZero();
        
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint96 selectorPosition = uint96(ds.selectors.length);

        for (uint256 i; i < _functionSelectors.length; i++) {
            bytes4 selector = _functionSelectors[i];
            address oldFacetAddress = ds.facetAddress[selector];
            
            if (oldFacetAddress != address(0)) revert FunctionAlreadyExists(selector);

            ds.facetAddress[selector] = _facetAddress;
            ds.selectorPosition[selector] = selectorPosition;
            ds.selectors.push(selector);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) private {
        if (_facetAddress == address(0)) revert FacetAddressIsZero();
        
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        for (uint256 i; i < _functionSelectors.length; i++) {
            bytes4 selector = _functionSelectors[i];
            address oldFacetAddress = ds.facetAddress[selector];

            if (oldFacetAddress == address(0)) revert FunctionDoesNotExist(selector);
            if (oldFacetAddress == _facetAddress) revert FunctionAlreadyExists(selector); // Optimasi: tidak perlu replace jika alamat sama

            // Note: Kita bisa menambahkan cek immutable disini jika diperlukan
            
            ds.facetAddress[selector] = _facetAddress;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) private {
        if (_facetAddress != address(0)) revert FacetAddressIsNotZero(); // Remove harus address(0)

        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        for (uint256 i; i < _functionSelectors.length; i++) {
            bytes4 selector = _functionSelectors[i];
            address oldFacetAddress = ds.facetAddress[selector];
            
            if (oldFacetAddress == address(0)) revert CannotRemoveFunctionThatDoesNotExist(selector);

            // Logic Swap-and-Pop untuk efisiensi array
            uint256 selectorPosition = ds.selectorPosition[selector];
            uint256 lastSelectorPosition = ds.selectors.length - 1;

            if (selectorPosition != lastSelectorPosition) {
                bytes4 lastSelector = ds.selectors[lastSelectorPosition];
                ds.selectors[selectorPosition] = lastSelector;
                ds.selectorPosition[lastSelector] = selectorPosition;
            }

            ds.selectors.pop();
            delete ds.selectorPosition[selector];
            delete ds.facetAddress[selector];
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) private {
        if (_init == address(0)) {
            return;
        }
        
        (bool success, bytes memory errorData) = _init.delegatecall(_calldata);
        
        if (!success) {
            if (errorData.length > 0) {
                // Bubble up error asli dari kontrak _init
                assembly {
                    let returndata_size := mload(errorData)
                    revert(add(32, errorData), returndata_size)
                }
            } else {
                revert InitCallFailed();
            }
        }
    }
}
