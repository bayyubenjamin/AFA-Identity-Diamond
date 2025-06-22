// test/AFA_Identity.test.ts (Corrected)

import { ethers } from "hardhat";
import { expect } from "chai";
import { Contract, ContractFactory, id } from "ethers";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { FacetCutAction, getSelectors } from "../scripts/libraries/diamond";
import { DiamondInit, FacetNames } from "../diamondConfig";

describe("AFA Identity Diamond Tests", function () {
    let diamond: Contract; // Now we interact with the diamond contract directly
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

        // 1. Deploy the main Diamond contract
        const DiamondFactory: ContractFactory = await ethers.getContractFactory("Diamond");
        const diamondContract = await DiamondFactory.deploy(owner.address);
        await diamondContract.waitForDeployment();
        diamondAddress = await diamondContract.getAddress();
        diamond = await ethers.getContractAt("Diamond", diamondAddress);

        // 2. Deploy Facets
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
        
        // 3. Perform the first diamondCut to add all facets
        const initFacetContract = facetContracts[DiamondInit];
        const functionCall = initFacetContract.interface.encodeFunctionData("initialize", [
            "AFA Identity",
            "AFAID",
            admin.address,
        ]);
        
        await diamond.connect(owner).diamondCut(cut, await initFacetContract.getAddress(), functionCall);

        // 4. Attach facet ABIs to the diamond address for testing
        ownershipFacet = await ethers.getContractAt("OwnershipFacet", diamondAddress);
        erc721Facet = await ethers.getContractAt("AFA_ERC721_Facet", diamondAddress);
        adminFacet = await ethers.getContractAt("AFA_Admin_Facet", diamondAddress);
        profileFacet = await ethers.getContractAt("AFA_Profile_Facet", diamondAddress);
    });

    // ... sisa dari test cases Anda bisa tetap sama ...
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
            await expect(
                adminFacet.connect(user1).mintIdentity(user2.address, "usertwo", "ipfs://meta2", proofHash)
            ).to.be.revertedWith("Diamond: Must be owner to cut"); // Reverted by diamondCut owner check
        });
    });
});
