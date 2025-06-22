import { ethers } from "hardhat";
import { expect } from "chai";
import { Contract } from "ethers";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { FacetCutAction, getSelectors } from "../scripts/libraries/diamond";
import { DiamondInit, FacetNames } from "../diamondConfig";

describe("AFAIdentityFacet Test", function () {
    let diamondAddress: string;
    let diamondCutFacet: Contract;
    let afaIdentityFacet: Contract;
    let owner: SignerWithAddress;
    let addr1: SignerWithAddress;
    let addr2: SignerWithAddress;

    // Deploy the diamond with all facets before each test
    beforeEach(async function () {
        [owner, addr1, addr2] = await ethers.getSigners();

        // Deploy Diamond
        const Diamond = await ethers.getContractFactory("Diamond");
        const diamond = await Diamond.deploy(owner.address);
        await diamond.waitForDeployment();
        diamondAddress = await diamond.getAddress();

        // Deploy Facets and perform DiamondCut
        const cut = [];
        let functionCall;

        for (const FacetName of FacetNames) {
            const Facet = await ethers.getContractFactory(FacetName);
            const facet = await Facet.deploy();
            await facet.waitForDeployment();
            
            cut.push({
                facetAddress: await facet.getAddress(),
                action: FacetCutAction.Add,
                functionSelectors: getSelectors(facet),
            });

            if (FacetName === DiamondInit) {
                functionCall = facet.interface.encodeFunctionData("init");
            }
        }

        diamondCutFacet = await ethers.getContractAt("IDiamondCut", diamondAddress);
        const initFacetAddress = (await ethers.getContractByName(DiamondInit)).target;
        
        const tx = await diamondCutFacet.diamondCut(cut, initFacetAddress, functionCall);
        await tx.wait();

        afaIdentityFacet = await ethers.getContractAt("AFAIdentityFacet", diamondAddress);
    });

    it("Should have correct name and symbol after initialization", async function () {
        expect(await afaIdentityFacet.name()).to.equal("AFA Identity");
        expect(await afaIdentityFacet.symbol()).to.equal("AFAID");
    });

    it("Should allow contract owner to mint an identity", async function () {
        const metadataURI = "ipfs://my-metadata-1";
        await expect(afaIdentityFacet.connect(owner).mintIdentity(addr1.address, metadataURI))
            .to.emit(afaIdentityFacet, "Transfer")
            .withArgs(ethers.ZeroAddress, addr1.address, 1);

        expect(await afaIdentityFacet.ownerOf(1)).to.equal(addr1.address);
        expect(await afaIdentityFacet.tokenURI(1)).to.equal(metadataURI);
    });

    it("Should NOT allow non-owner to mint an identity", async function () {
        await expect(
            afaIdentityFacet.connect(addr1).mintIdentity(addr2.address, "ipfs://...")
        ).to.be.revertedWith("AFAIdentity: Only contract owner can mint");
    });
    
    it("Should allow token holder to update metadata", async function () {
        const initialURI = "ipfs://initial";
        const newURI = "ipfs://updated";
        
        // Owner mints to addr1
        await afaIdentityFacet.connect(owner).mintIdentity(addr1.address, initialURI);
        
        // addr1 updates their own token
        await expect(afaIdentityFacet.connect(addr1).updateMetadata(1, newURI))
            .to.not.be.reverted;

        expect(await afaIdentityFacet.tokenURI(1)).to.equal(newURI);
    });
    
    it("Should NOT allow others to update metadata", async function () {
        const initialURI = "ipfs://initial";
        await afaIdentityFacet.connect(owner).mintIdentity(addr1.address, initialURI);
        
        // Owner tries to update addr1's token (not allowed by default unless approved)
        await expect(
            afaIdentityFacet.connect(owner).updateMetadata(1, "ipfs://...")
        ).to.be.revertedWith("AFAIdentity: Caller is not owner nor approved");
        
        // addr2 tries to update addr1's token
        await expect(
            afaIdentityFacet.connect(addr2).updateMetadata(1, "ipfs://...")
        ).to.be.revertedWith("AFAIdentity: Caller is not owner nor approved");
    });

    it("Should allow token holder to burn their token", async function () {
        await afaIdentityFacet.connect(owner).mintIdentity(addr1.address, "ipfs://...");
        
        // addr1 burns token 1
        await expect(afaIdentityFacet.connect(addr1).burn(1))
            .to.emit(afaIdentityFacet, "Transfer")
            .withArgs(addr1.address, ethers.ZeroAddress, 1);
            
        // Check that the token no longer exists
        await expect(afaIdentityFacet.ownerOf(1)).to.be.revertedWith("ERC721: invalid token ID");
    });
});
