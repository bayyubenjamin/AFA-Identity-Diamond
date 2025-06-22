// test/AFA_Identity.test.ts (Corrected)

import { ethers } from "hardhat";
import { expect } from "chai";
import { Contract, ContractFactory, id } from "ethers";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { getSelectors } from "../scripts/libraries/diamond";
import { DiamondInit, FacetNames } from "../diamondConfig";

describe("AFA Identity Diamond Tests", function () {
    let diamond: Contract;
    let diamondAddress: string;
    let ownershipFacet: Contract;
    let erc721Facet: Contract;
    let adminFacet: Contract;
    let profileFacet: Contract;

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
        diamond = await ethers.getContractAt("Diamond", diamondAddress);

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
                functionSelectors: getSelectors(facet),
            });
        }
        
        const initFacetContract = facetContracts[DiamondInit];
        const functionCall = initFacetContract.interface.encodeFunctionData("initialize", [
            "AFA Identity",
            "AFAID",
            admin.address,
        ]);
        
        await diamond.connect(owner).diamondCut(cut, await initFacetContract.getAddress(), functionCall);

        ownershipFacet = await ethers.getContractAt("OwnershipFacet", diamondAddress);
        erc721Facet = await ethers.getContractAt("AFA_ERC721_Facet", diamondAddress);
        adminFacet = await ethers.getContractAt("AFA_Admin_Facet", diamondAddress);
        profileFacet = await ethers.getContractAt("AFA_Profile_Facet", diamondAddress);
    });

    describe("Admin Facet", function() {
        it("should have correct owner set during initialization", async function() {
            expect(await ownershipFacet.owner()).to.equal(owner.address);
        });
        
        it("should allow admin to mint an identity for a user", async function() {
            const proofHash = id("proof_for_user1");
            await expect(adminFacet.connect(admin).mintIdentity(user1.address, "userone", "ipfs://meta1", proofHash))
                .to.emit(erc721Facet, "Transfer")
                .withArgs(ethers.ZeroAddress, user1.address, 1);

            expect(await erc721Facet.ownerOf(1)).to.equal(user1.address);
        });

        it("should NOT allow a non-admin to mint an identity", async function() {
            const proofHash = id("proof_for_user2");
            // --- PERBAIKAN DI SINI ---
            // Ekspektasi diubah agar sesuai dengan pesan error dari modifier 'onlyAdmin'
            await expect(
                adminFacet.connect(user1).mintIdentity(user2.address, "usertwo", "ipfs://meta2", proofHash)
            ).to.be.revertedWith("AFA: Must be admin");
        });
    });

    describe("Profile Facet", function() {
        beforeEach(async function() {
            const proofHash = id("proof_for_user1_profile_tests");
            await adminFacet.connect(admin).mintIdentity(user1.address, "userone", "ipfs://meta1", proofHash);
        });

        it("should allow user to get their own token ID", async function() {
            expect(await profileFacet.connect(user1).getMyTokenId()).to.equal(1);
        });

        it("should allow user to burn their own identity", async function() {
            const tokenId = await profileFacet.connect(user1).getMyTokenId();
            expect(tokenId).to.equal(1);

            await expect(profileFacet.connect(user1).burnMyIdentity())
                .to.emit(erc721Facet, "Transfer")
                .withArgs(user1.address, ethers.ZeroAddress, tokenId);
            
            await expect(erc721Facet.ownerOf(tokenId)).to.be.revertedWith("ERC721: invalid token ID");
        });
    });
});
