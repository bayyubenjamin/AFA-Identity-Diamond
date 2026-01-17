// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Sources flattened with hardhat v2.26.3 https://hardhat.org

// SPDX-License-Identifier: MIT

// File contracts/interfaces/IDiamondCut.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.24;

interface IDiamondCut {
    enum FacetCutAction { Add, Replace, Remove }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}


// File contracts/diamond/libraries/LibDiamond.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.24;

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct DiamondStorage {
        mapping(bytes4 => address) facetAddress;
        bytes4[] selectors;
        mapping(bytes4 => uint256) selectorPosition;
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
    
    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);
    
    function setContractOwner(address _owner) internal {
        DiamondStorage storage ds = diamondStorage();
        ds.contractOwner = _owner;
    }

    function contractOwner() internal view returns (address owner_) {
        owner_ = diamondStorage().contractOwner;
    }

    function enforceIsOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }
}


// File contracts/facets/DiamondCutFacet.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.24;


contract DiamondCutFacet is IDiamondCut {
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {
        LibDiamond.enforceIsOwner();
        for (uint256 i = 0; i < _diamondCut.length; i++) {
            FacetCutAction action = _diamondCut[i].action;
            address facetAddress = _diamondCut[i].facetAddress;
            bytes4[] memory functionSelectors = _diamondCut[i].functionSelectors;
            if (action == FacetCutAction.Add) {
                addFunctions(functionSelectors, facetAddress);
            } else if (action == FacetCutAction.Replace) {
                replaceFunctions(functionSelectors, facetAddress);
            } else if (action == FacetCutAction.Remove) {
                removeFunctions(functionSelectors);
            } else {
                revert("DiamondCut: Incorrect Action");
            }
        }
        emit LibDiamond.DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(bytes4[] memory _functionSelectors, address _facetAddress) private {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(_facetAddress != address(0), "DiamondCut: Address is zero");
        for (uint256 i = 0; i < _functionSelectors.length; i++) {
            bytes4 selector = _functionSelectors[i];
            require(ds.facetAddress[selector] == address(0), "DiamondCut: Can't add function that already exists");
            ds.facetAddress[selector] = _facetAddress;
            ds.selectors.push(selector);
            ds.selectorPosition[selector] = ds.selectors.length - 1;
        }
    }

    function replaceFunctions(bytes4[] memory _functionSelectors, address _facetAddress) private {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(_facetAddress != address(0), "DiamondCut: Address is zero");
        for (uint256 i = 0; i < _functionSelectors.length; i++) {
            bytes4 selector = _functionSelectors[i];
            require(ds.facetAddress[selector] != address(0), "DiamondCut: Can't replace function that doesn't exist");
            ds.facetAddress[selector] = _facetAddress;
        }
    }

    function removeFunctions(bytes4[] memory _functionSelectors) private {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        for (uint256 i = 0; i < _functionSelectors.length; i++) {
            bytes4 selector = _functionSelectors[i];
            uint256 position = ds.selectorPosition[selector];
            require(position != 0 || ds.selectors[0] == selector, "DiamondCut: Can't remove function that doesn't exist");
            bytes4 lastSelector = ds.selectors[ds.selectors.length - 1];
            ds.selectors[position] = lastSelector;
            ds.selectorPosition[lastSelector] = position;
            ds.selectors.pop();
            delete ds.facetAddress[selector];
            delete ds.selectorPosition[selector];
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) private {
        if (_init != address(0)) {
            (bool success, ) = _init.delegatecall(_calldata);
            require(success, "DiamondCut: _init call failed");
        }
    }
}
