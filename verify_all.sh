#!/bin/bash

echo "Verifying all facets on optimismSepolia..."

npx hardhat verify --network optimismSepolia 0xEa8503548Cfbc31a46B06C5d27f6fD6566656E35 # DiamondCutFacet
npx hardhat verify --network optimismSepolia 0x4BBf71c2280B16Fd3A14bd19c2b1eB6DC16eeE5a # DiamondLoupeFacet
npx hardhat verify --network optimismSepolia 0x47273Cce433982e35A99387C5db281AC4a2c4767 # OwnershipFacet
npx hardhat verify --network optimismSepolia 0x3abbCDB5d61d14948DEe784b7B17Dc51E9eBe189 # IdentityCoreFacet
npx hardhat verify --network optimismSepolia 0xa67404E44bdb62835486066cBdF8f2a9e07CD9Ac # AttestationFacet
npx hardhat verify --network optimismSepolia 0xA6dfeAd9F0eb041865187356956b5493b9B1c1d2 # SubscriptionManagerFacet
npx hardhat verify --network optimismSepolia 0xF2bF0Fa36BC64C090daE353C67A0aa3533b8e4ac # TestingAdminFacet

echo "Selesai."
