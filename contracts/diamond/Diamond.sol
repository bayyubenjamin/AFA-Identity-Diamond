// contracts/diamond/Diamond.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { LibDiamond } from "./libraries/LibDiamond.sol";

contract Diamond {
    // --- Structs and Events moved here from the library ---
    enum FacetCutAction { Add, Replace, Remove }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);

    constructor(address _contractOwner) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.contractOwner = _contractOwner;
    }

    fallback() external payable {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        address facetAddress = ds.facetAddressForSelector[msg.sig];
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

    // --- diamondCut logic is now part of the main Diamond contract ---
    function diamondCut(
        FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(msg.sender == ds.contractOwner, "Diamond: Must be owner to cut");

        for (uint256 i = 0; i < _diamondCut.length; i++) {
            FacetCutAction action = _diamondCut[i].action;
            address facetAddress = _diamondCut[i].facetAddress;
            bytes4[] memory functionSelectors = _diamondCut[i].functionSelectors;

            if (action == FacetCutAction.Add) {
                addFunctions(ds, functionSelectors, facetAddress);
            } else if (action == FacetCutAction.Replace) {
                replaceFunctions(ds, functionSelectors, facetAddress);
            } else if (action == FacetCutAction.Remove) {
                removeFunctions(ds, functionSelectors);
            } else {
                revert("DiamondCut: Incorrect Action");
            }
        }
        
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(LibDiamond.DiamondStorage storage ds, bytes4[] memory _functionSelectors, address _facetAddress) private {
        for (uint256 i = 0; i < _functionSelectors.length; i++) {
            bytes4 selector = _functionSelectors[i];
            require(ds.facetAddressForSelector[selector] == address(0), "DiamondCut: Can't add function that already exists");
            ds.facetAddressForSelector[selector] = _facetAddress;
        }
    }

    function replaceFunctions(LibDiamond.DiamondStorage storage ds, bytes4[] memory _functionSelectors, address _facetAddress) private {
        for (uint256 i = 0; i < _functionSelectors.length; i++) {
            bytes4 selector = _functionSelectors[i];
            require(ds.facetAddressForSelector[selector] != address(0), "DiamondCut: Can't replace function that doesn't exist");
            ds.facetAddressForSelector[selector] = _facetAddress;
        }
    }

    function removeFunctions(LibDiamond.DiamondStorage storage ds, bytes4[] memory _functionSelectors) private {
        for (uint256 i = 0; i < _functionSelectors.length; i++) {
            bytes4 selector = _functionSelectors[i];
            require(ds.facetAddressForSelector[selector] != address(0), "DiamondCut: Can't remove function that doesn't exist");
            delete ds.facetAddressForSelector[selector];
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) private {
        if (_init != address(0)) {
            (bool success, ) = _init.delegatecall(_calldata);
            require(success, "DiamondCut: _init call failed");
        }
    }
}
