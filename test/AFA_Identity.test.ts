// test/AFA_Identity.test.ts

import { ethers } from "hardhat";
import { expect } from "chai";
import { Contract, ContractFactory } from "ethers";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { getSelectors } from "../scripts/libraries/diamond";
import { DiamondInit, FacetNames } from "../diamondConfig";

describe("AFA Identity Diamond Tests", function () {
    let diamondAddress: string;
    let ownershipFacet: Contract;
    let testingAdminFacet: Contract;
    let attestationFacet: Contract;
    let identityCoreFacet: Contract;

    let owner: SignerWithAddress;
    let admin: SignerWithAddress;
    let user1: SignerWithAddress;
    let user2: SignerWithAddress;

    const FacetCutAction = { Add: 0, Replace: 1, Remove: 2 };

    beforeEach(async function () {
        [owner, user1, user2] = await ethers.getSigners();
        admin = owner;

        // --- PERBAIKAN DI SINI ---
        // 1. Deploy DiamondCutFacet terlebih dahulu karena dibutuhkan oleh konstruktor Diamond
        const DiamondCutFacetFactory = await ethers.getContractFactory("DiamondCutFacet");
        const diamondCutFacet = await DiamondCutFacetFactory.deploy();
        await diamondCutFacet.waitForDeployment();

        // 2. Deploy Diamond dengan DUA argumen yang benar
        const DiamondFactory: ContractFactory = await ethers.getContractFactory("Diamond");
        const diamondContract = await DiamondFactory.deploy(owner.address, await diamondCutFacet.getAddress());
        await diamondContract.waitForDeployment();
        diamondAddress = await diamondContract.getAddress();
        
        // 3. Deploy sisa facet lainnya
        const cut = [];
        const facetContracts: { [key: string]: Contract } = {
            'DiamondCutFacet': diamondCutFacet // Masukkan yang sudah di-deploy
        };
        
        const otherFacetNames = FacetNames.filter(name => name !== 'DiamondCutFacet');

        for (const facetName of otherFacetNames) {
            const FacetFactory: ContractFactory = await ethers.getContractFactory(facetName);
            const facet = await FacetFactory.deploy();
            await facet.waitForDeployment();
            facetContracts[facetName] = facet;
        }

        // Siapkan 'cut' untuk semua facet (termasuk DiamondCutFacet)
        for (const facetName of FacetNames) {
             cut.push({
                facetAddress: await facetContracts[facetName].getAddress(),
                action: FacetCutAction.Add,
                functionSelectors: getSelectors(facetContracts[facetName]),
            });
        }
        
        const initFacetContract = facetContracts[DiamondInit];
        const verifierAddressForTest = admin.address;
        const baseURIForTest = "https://test.api.afa.io/metadata/";
        const functionCall = initFacetContract.interface.encodeFunctionData("initialize", [
            verifierAddressForTest,
            baseURIForTest
        ]);
        
        const diamondCutInstance = await ethers.getContractAt("IDiamondCut", diamondAddress);
        // Hapus selector diamondCut dari cut karena sudah ditambahkan di constructor
        cut[0].functionSelectors = []; 

        await diamondCutInstance.connect(owner).diamondCut(cut, await initFacetContract.getAddress(), functionCall);

        // Update instance kontrak untuk testing
        ownershipFacet = await ethers.getContractAt("OwnershipFacet", diamondAddress);
        testingAdminFacet = await ethers.getContractAt("TestingAdminFacet", diamondAddress);
        attestationFacet = await ethers.getContractAt("AttestationFacet", diamondAddress);
        identityCoreFacet = await ethers.getContractAt("IdentityCoreFacet", diamondAddress);
    });

    // ... sisa tes Anda tidak perlu diubah ...
    describe("TestingAdminFacet", function() {
        it("should have correct owner set during initialization", async function() {
            expect(await ownershipFacet.owner()).to.equal(owner.address);
        });
        
        it("should allow admin to mint an identity for a user using adminMint", async function() {
            await expect(testingAdminFacet.connect(admin).adminMint(user1.address))
                .to.emit(testingAdminFacet, "AdminIdentityMinted")
                .withArgs(user1.address, 1);

            expect(await identityCoreFacet.ownerOf(1)).to.equal(user1.address);
            expect(await attestationFacet.isPremium(1)).to.be.true;
        });

        it("should NOT allow a non-admin to call adminMint", async function() {
            await expect(
                testingAdminFacet.connect(user1).adminMint(user2.address)
            ).to.be.revertedWith("AFA: Must be admin");
        });
    });
});
