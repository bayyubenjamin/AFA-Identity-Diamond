// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { LibDiamond } from "../diamond/libraries/LibDiamond.sol";

library LibTreasuryStorage {
    bytes32 constant STORAGE_POSITION = keccak256("afa.identity.treasury.storage.v1");

    struct Layout {
        uint256 totalRevenue;
        uint256 totalWithdrawn;
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly { s.slot := position }
    }
}

contract TreasuryFacet {
    event FundsWithdrawn(address indexed to, uint256 amount);
    event FundsReceived(address indexed from, uint256 amount);

    // Menerima ETH/Native Coin
    receive() external payable {
        LibTreasuryStorage.Layout storage s = LibTreasuryStorage.layout();
        s.totalRevenue += msg.value;
        emit FundsReceived(msg.sender, msg.value);
    }

    function withdrawTreasury(address payable _to, uint256 _amount) external {
        LibDiamond.enforceIsOwner(); // Hanya owner yang boleh tarik uang
        
        LibTreasuryStorage.Layout storage s = LibTreasuryStorage.layout();
        require(address(this).balance >= _amount, "Treasury: Insufficient balance");

        s.totalWithdrawn += _amount;
        
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Treasury: Transfer failed");

        emit FundsWithdrawn(_to, _amount);
    }

    function getTreasuryStats() external view returns (uint256 balance, uint256 revenue, uint256 withdrawn) {
        LibTreasuryStorage.Layout storage s = LibTreasuryStorage.layout();
        return (address(this).balance, s.totalRevenue, s.totalWithdrawn);
    }
}
