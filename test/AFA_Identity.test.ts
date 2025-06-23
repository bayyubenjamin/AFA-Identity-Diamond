// test/AFA_Identity.test.ts

import { ethers } from "hardhat";
import { expect } from "chai";
import { Contract, ContractFactory, id } from "ethers";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { getSelectors } from "../scripts/libraries/diamond";
import { DiamondInit, FacetNames } from "../diamondConfig"; // Pastikan path ini benar

describe("AFA Identity Diamond Tests", function () {
    let diamondAddress: string;
    let ownershipFacet: Contract;
    let testingAdminFacet: Contract; // Kita akan menggunakan facet testing
    let attestationFacet: Contract;
    let identityCoreFacet: Contract;

    let owner: SignerWithAddress;
    let admin: SignerWithAddress;
    let user1: SignerWithAddress;
    let user2: SignerWithAddress;

    const FacetCut = {
        Add: 0,
        Replace: 1,
        Remove: 2
    };

    beforeEach(async function () {
        [owner, user1, user2] = await ethers.getSigners();
        admin = owner;

        const DiamondFactory: ContractFactory = await ethers.getContractFactory("Diamond");
        const diamondContract = await DiamondFactory.deploy(owner.address);
        await diamondContract.waitForDeployment();
        diamondAddress = await diamondContract.getAddress();
        
        const cut = [];
        const facetContracts: { [key: string]: Contract } = {};
        for (const facetName of FacetNames) {
            const FacetFactory: ContractFactory = await ethers.getContractFactory(facetName);
            const facet = await FacetFactory.deploy();
            await facet.waitForDeployment();
            facetContracts[facetName] = facet;
            cut.push({
                facetAddress: await facet.getAddress(),
                action: FacetCut.Add,
                functionSelectors: getSelectors(facet as any), // Cast as any to bypass potential type issues
            });
        }
        
        const initFacetContract = facetContracts[DiamondInit]; // Ini adalah SubscriptionManagerFacet

        // --- PERBAIKAN DI SINI ---
        // Panggil `initialize` dengan argumen yang benar (verifierAddress, baseURI)
        const verifierAddressForTest = admin.address; // Untuk tes, kita gunakan alamat admin
        const baseURIForTest = "https://test.api.afa.io/metadata/";
        const functionCall = initFacetContract.interface.encodeFunctionData("initialize", [
            verifierAddressForTest,
            baseURIForTest
        ]);
        
        const diamond = await ethers.getContractAt("IDiamondCut", diamondAddress);
        await diamond.connect(owner).diamondCut(cut, await initFacetContract.getAddress(), functionCall);

        // Update instance kontrak untuk testing
        ownershipFacet = await ethers.getContractAt("OwnershipFacet", diamondAddress);
        testingAdminFacet = await ethers.getContractAt("TestingAdminFacet", diamondAddress);
        attestationFacet = await ethers.getContractAt("AttestationFacet", diamondAddress);
        identityCoreFacet = await ethers.getContractAt("IdentityCoreFacet", diamondAddress);
    });

    // --- SESUAIKAN TES ANDA DENGAN FUNGSI BARU ---
    describe("TestingAdminFacet", function() {
        it("should have correct owner set during initialization", async function() {
            expect(await ownershipFacet.owner()).to.equal(owner.address);
        });
        
        it("should allow admin to mint an identity for a user using adminMint", async function() {
            // Kita sekarang menggunakan fungsi adminMint dari TestingAdminFacet
            await expect(testingAdminFacet.connect(admin).adminMint(user1.address))
                .to.emit(testingAdminFacet, "AdminIdentityMinted") // Event baru
                .withArgs(user1.address, 1);

            expect(await identityCoreFacet.ownerOf(1)).to.equal(user1.address);
            
            // Cek juga status premiumnya
            expect(await attestationFacet.isPremium(1)).to.be.true;
        });

        it("should NOT allow a non-admin to call adminMint", async function() {
            await expect(
                testingAdminFacet.connect(user1).adminMint(user2.address)
            ).to.be.revertedWith("AFA: Must be admin");
        });
    });
});
