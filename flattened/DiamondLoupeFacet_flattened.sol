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


// File contracts/interfaces/IDiamondLoupe.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.24;

interface IDiamondLoupe {
    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /**
     * @notice Gets all facets and their selectors.
     * @return facets_ The facets and their selectors.
     */
    function facets() external view returns (Facet[] memory facets_);

    /**
     * @notice Gets all the function selectors supported by a specific facet.
     * @param _facet The facet address.
     * @return facetFunctionSelectors_ The selectors.
     */
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /**
     * @notice Get all the facet addresses used by the diamond.
     * @return facetAddresses_ The facet addresses.
     */
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /**
     * @notice Gets the facet that supports the given selector.
     * @dev If selector is not supported return address(0).
     * @param _functionSelector The selector.
     * @return facetAddress_ The facet address.
     */
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}


// File contracts/facets/DiamondLoupeFacet.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.24;


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
