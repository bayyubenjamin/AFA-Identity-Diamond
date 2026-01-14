import { ethers } from "hardhat";
import { expect } from "chai";
import { Contract, ContractFactory } from "ethers";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { getSelectors } from "../scripts/libraries/diamond";
import { DiamondInit, FacetNames } from "../diamondConfig";

describe("AFA Identity Diamond Tests", function () {
    let diamondAddress: string;
    let ownershipFacet: Contract;
    let testingAdminFacet: Contract; // Opsional jika masih ada
    let identityCoreFacet: Contract;

    let owner: SignerWithAddress;
    let admin: SignerWithAddress;
    let user1: SignerWithAddress;
    let user2: SignerWithAddress;

    const FacetCutAction = { Add: 0, Replace: 1, Remove: 2 };

    beforeEach(async function () {
        [owner, user1, user2] = await ethers.getSigners();
        admin = owner; // Admin juga bertindak sebagai Verifier

        // 1. Deploy DiamondCutFacet
        const DiamondCutFacetFactory = await ethers.getContractFactory("DiamondCutFacet");
        const diamondCutFacet = await DiamondCutFacetFactory.deploy();
        await diamondCutFacet.waitForDeployment();

        // 2. Deploy Diamond
        const DiamondFactory: ContractFactory = await ethers.getContractFactory("Diamond");
        const diamondContract = await DiamondFactory.deploy(owner.address, await diamondCutFacet.getAddress());
        await diamondContract.waitForDeployment();
        diamondAddress = await diamondContract.getAddress();
        
        // 3. Deploy Facets
        const cut = [];
        const facetContracts: { [key: string]: Contract } = {
            'DiamondCutFacet': diamondCutFacet 
        };
        
        // Pastikan IdentityCoreFacet ada di list FacetNames di diamondConfig.js
        const otherFacetNames = FacetNames.filter(name => name !== 'DiamondCutFacet');

        for (const facetName of otherFacetNames) {
            const FacetFactory: ContractFactory = await ethers.getContractFactory(facetName);
            const facet = await FacetFactory.deploy();
            await facet.waitForDeployment();
            facetContracts[facetName] = facet;
        }

        for (const facetName of FacetNames) {
             cut.push({
                facetAddress: await facetContracts[facetName].getAddress(),
                action: FacetCutAction.Add,
                functionSelectors: getSelectors(facetContracts[facetName]),
            });
        }
        
        // Initialize Diamond
        const initFacetContract = facetContracts[DiamondInit];
        // Verifier address diset ke 'admin' (owner)
        const verifierAddressForTest = admin.address; 
        const baseURIForTest = "https://test.api.afa.io/metadata/";
        const functionCall = initFacetContract.interface.encodeFunctionData("initialize", [
            verifierAddressForTest,
            baseURIForTest
        ]);
        
        const diamondCutInstance = await ethers.getContractAt("IDiamondCut", diamondAddress);
        cut[0].functionSelectors = []; 

        await diamondCutInstance.connect(owner).diamondCut(cut, await initFacetContract.getAddress(), functionCall);

        // Connect Instances
        ownershipFacet = await ethers.getContractAt("OwnershipFacet", diamondAddress);
        // Pastikan nama facet sesuai dengan nama file kontrak
        identityCoreFacet = await ethers.getContractAt("IdentityCoreFacet", diamondAddress);
    });

    describe("IdentityCoreFacet EIP-712 Minting", function() {
        it("should allow user to mint identity using valid EIP-712 signature", async function() {
            // Persiapan Data EIP-712
            const network = await ethers.provider.getNetwork();
            const chainId = network.chainId;

            const domain = {
                name: "Afa Identity",
                version: "1",
                chainId: chainId,
                verifyingContract: diamondAddress // Alamat Diamond, bukan Facet!
            };

            const types = {
                MintIdentity: [
                    { name: "recipient", type: "address" },
                    { name: "nonce", type: "uint256" }
                ]
            };

            const value = {
                recipient: user1.address,
                nonce: 0 // Nonce awal user1
            };

            // Sign Typed Data (Admin/Verifier menandatangani)
            const signature = await admin.signTypedData(domain, types, value);

            // User submit signature
            await expect(identityCoreFacet.connect(user1).mintIdentity(signature))
                .to.not.be.reverted;

            // Verifikasi
            const identityData = await identityCoreFacet.getIdentity(user1.address);
            expect(identityData[0]).to.not.equal(0); // TokenId tidak boleh 0
        });

        it("should REVERT if signature is used by wrong user (Front-running protection)", async function() {
            const network = await ethers.provider.getNetwork();
            const domain = {
                name: "Afa Identity",
                version: "1",
                chainId: network.chainId,
                verifyingContract: diamondAddress 
            };

            const types = {
                MintIdentity: [
                    { name: "recipient", type: "address" }, // Signed untuk User 1
                    { name: "nonce", type: "uint256" }
                ]
            };

            const value = {
                recipient: user1.address, 
                nonce: 0 
            };

            const signature = await admin.signTypedData(domain, types, value);

            // User 2 mencoba memakai signature milik User 1
            await expect(identityCoreFacet.connect(user2).mintIdentity(signature))
                .to.be.revertedWithCustomError(identityCoreFacet, "Identity_InvalidSignature");
        });

        it("should REVERT if signature is reused (Replay Protection)", async function() {
             const network = await ethers.provider.getNetwork();
             const domain = {
                 name: "Afa Identity",
                 version: "1",
                 chainId: network.chainId,
                 verifyingContract: diamondAddress 
             };
 
             const types = {
                 MintIdentity: [
                     { name: "recipient", type: "address" },
                     { name: "nonce", type: "uint256" }
                 ]
             };
 
             const value = {
                 recipient: user1.address,
                 nonce: 0 
             };
 
             const signature = await admin.signTypedData(domain, types, value);
 
             // Mint pertama sukses
             await identityCoreFacet.connect(user1).mintIdentity(signature);
 
             // Mint kedua dengan signature sama harus gagal (karena nonce on-chain sudah naik)
             await expect(identityCoreFacet.connect(user1).mintIdentity(signature))
                .to.be.revertedWithCustomError(identityCoreFacet, "Identity_AlreadyHasIdentity");
                // Atau jika logika mengizinkan update, errornya akan "Identity_InvalidSignature" karena nonce mismatch
        });
    });
});
