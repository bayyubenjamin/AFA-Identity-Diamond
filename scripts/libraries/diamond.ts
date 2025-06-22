import { Contract, FunctionFragment } from "ethers";

export const FacetCutAction = { Add: 0, Replace: 1, Remove: 2 };

// get function selectors from ABI
export function getSelectors(contract: Contract): string[] {
    const selectors: string[] = [];
    contract.interface.forEachFunction((func: FunctionFragment) => {
        if (func.name !== '') {
            selectors.push(func.selector);
        }
    });
    return selectors;
}

// remove selectors using an array of signatures
export function removeSelectors(selectors: string[], signatures: string[]): string[] {
    const removeSet = new Set(signatures);
    return selectors.filter((sel) => !removeSet.has(sel));
}
