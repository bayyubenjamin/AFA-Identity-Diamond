// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IOwnershipFacet {
    function owner() external view returns (address owner_);
}
