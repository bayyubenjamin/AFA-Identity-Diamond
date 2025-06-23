// diamondConfig.ts

// The initializer function will be moved to our new SubscriptionManagerFacet
export const DiamondInit = 'SubscriptionManagerFacet';

export const FacetNames = [
    // Standard Diamond facets
    'DiamondLoupeFacet',
    'OwnershipFacet',
    
    // AFA Identity Core Facets (New & Updated)
    'IdentityCoreFacet',          // Replaces AFA_ERC721_Facet, handles soulbound logic and baseURI
    'AttestationFacet',           // New: Manages premium status and expiration
    'SubscriptionManagerFacet',   // New: Manages pricing, payments, minting, and renewals
];
