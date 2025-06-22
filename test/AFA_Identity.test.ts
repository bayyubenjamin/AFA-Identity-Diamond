// test/AFA_Identity.test.ts (Corrected)

import { ethers } from "hardhat";
import { expect } from "chai";
import { Contract, ContractFactory, id } from "ethers";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { FacetCutAction, getSelectors } from "../scripts/libraries/diamond";
import { DiamondInit, FacetNames } from "../diamondConfig";

describe("AFA Identity Diamond Tests", function () {
    let diamondAddress: string;
    let ownershipFacet: Contract;
    let erc721Facet: Contract;
    let adminFacet: Contract;
    let profileFacet: Contract;

    let owner: SignerWithAddress;
    let admin: SignerWithAddress;
    let user1: SignerWithAddress;
    let user2: SignerWithAddress;

    beforeEach(async function () {
        [owner, user1, user2] = await ethers.getSigners();
        admin = owner;

        // 1. Deploy all Facets first
        const facets: { [key: string]: Contract } = {};
        for (const facetName of FacetNames) {
            const FacetFactory: ContractFactory = await ethers.getContractFactory(facetName);
            const facet = await FacetFactory.deploy();
            await facet.waitForDeployment();
            facets[facetName] = facet;
        }

        // 2. Prepare the initial diamondCut data
        const initialCut = [];
        for (const facetName of FacetNames) {
            initialCut.push({
                facetAddress: await facets[facetName].getAddress(),
                action: FacetCutAction.Add,
                functionSelectors: getSelectors(facets[facetName]),
            });
        }
        
        // 3. Deploy the Diamond with the initial cut in the constructor
        const DiamondFactory: ContractFactory = await ethers.getContractFactory("Diamond");
        const diamond = await DiamondFactory.deploy(owner.address, initialCut);
        await diamond.waitForDeployment();
        diamondAddress = await diamond.getAddress();

        // 4. Call the initializer function separately
        const initFacet = await ethers.getContractAt(DiamondInit, diamondAddress);
        const functionCall = initFacet.interface.encodeFunctionData("initialize", [
            "AFA Identity",
            "AFAID",
            admin.address,
        ]);
        
        const diamondCutFacet = await ethers.getContractAt("DiamondCutFacet", diamondAddress);

        // We use diamondCut to call the initializer.
        // The cut data is empty because we already did the initial cut.
        await diamondCutFacet.diamondCut([], await initFacet.getAddress(), functionCall);

        // 5. Attach other facets for testing
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
            expect(await erc721Facet.balanceOf(user1.address)).to.equal(1);
        });

        it("should NOT allow a non-admin to mint an identity", async function() {
            const proofHash = id("proof_for_user2");
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
