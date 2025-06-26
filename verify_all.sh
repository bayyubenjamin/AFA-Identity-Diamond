#!/bin/bash

echo "Verifying all facets on optimismSepolia..."

npx hardhat verify --network optimismSepolia 0x3743b653dE0ff9c93c6368FCc57886d65C1aE459 # DiamondCutFacet
npx hardhat verify --network optimismSepolia 0x834EB2C054a1EA34B3f6A5D77e6647A5546aF41e # DiamondLoupeFacet
npx hardhat verify --network optimismSepolia 0x8DdEEa19fe357253e99813c91c0E70b9Bd4D3622 # OwnershipFacet
npx hardhat verify --network optimismSepolia 0x1270aE6FCf2a20f18C72D903e671390689Aced1F # IdentityCoreFacet
npx hardhat verify --network optimismSepolia 0xC9E33628B4FD2a12A2b2f3527c4c31C0932427cc # AttestationFacet
npx hardhat verify --network optimismSepolia 0xB872A87F3F8dc19D07bdF06A978a62bC750CBC94 # SubscriptionManagerFacet
npx hardhat verify --network optimismSepolia 0x1ac257D72A851b058442219d79aF86Bf4E632194 # TestingAdminFacet

echo "Selesai."
