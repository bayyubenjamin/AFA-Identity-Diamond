#!/bin/bash

echo "🔍 Verifying facets on baseSepolia..."

npx hardhat verify --network baseSepolia 0x42C58e3AdA7BADF565c248bd124C7198Bf3a0d29 # DiamondCutFacet
npx hardhat verify --network baseSepolia 0xbd0E0E87faCF61d4E6E09aD014C757F84191c951 # DiamondLoupeFacet
npx hardhat verify --network baseSepolia 0x978E6DD78a41dF828FeE91EfAEaE6827f058d425 # OwnershipFacet
npx hardhat verify --network baseSepolia 0x1b3CeA9A1A33698c5eFdBF1cEA667Bc5f588030c # IdentityCoreFacet
npx hardhat verify --network baseSepolia 0x2A4d42DB2cb752d0dE7973cB9582baAae7229cd4 # AttestationFacet
npx hardhat verify --network baseSepolia 0x5f2337639b0d8E6563d2B73f9b126774048a815b # SubscriptionManagerFacet
npx hardhat verify --network baseSepolia 0x6a86e4dd3d1159795cBebE2aeD97A66be489aF70 # TestingAdminFacet

echo "✅ All facets verification attempt done."
