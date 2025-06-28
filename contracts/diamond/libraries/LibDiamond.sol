// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IDiamondCut} from "../../interfaces/IDiamondCut.sol";

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
