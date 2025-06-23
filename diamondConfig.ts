// diamondConfig.ts

// The initializer function will be called on the SubscriptionManagerFacet
export const DiamondInit = 'SubscriptionManagerFacet';

// The list of all facets to be deployed and added to the diamond
export const FacetNames = [
    // Standard Diamond facets for introspection and ownership
    'DiamondLoupeFacet',
    'OwnershipFacet',
    
    // AFA Identity Core Facets (The main V2 architecture)
    'IdentityCoreFacet',          // Handles core ERC721 logic, soulbound nature, and baseURI for metadata
    'AttestationFacet',           // Manages premium status and expiration timestamps
    'SubscriptionManagerFacet',   // Manages pricing, payments, signature verification, and the main minting logic
    'TestingAdminFacet'           // Contains admin-only functions for testing, like minting without payment/signature
];
