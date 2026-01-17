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


// File contracts/facets/OwnershipFacet.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.20;

contract OwnershipFacet {
    function owner() external view returns (address owner_) {
        owner_ = LibDiamond.diamondStorage().contractOwner;
    }

    function transferOwnership(address _newOwner) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(msg.sender == ds.contractOwner, "OwnershipFacet: Must be contract owner");
        
        require(_newOwner != address(0), "Ownership: New owner is the zero address");
        ds.contractOwner = _newOwner;
    }

    function withdraw() external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        require(msg.sender == ds.contractOwner, "OwnershipFacet: Must be contract owner");
        
        (bool success, ) = ds.contractOwner.call{value: address(this).balance}("");
        require(success, "Withdrawal: ETH transfer failed");
    }
}
