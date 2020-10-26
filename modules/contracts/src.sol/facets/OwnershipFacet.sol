// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "../lib/LibFacetStorage.sol";
import "../interfaces/IERC173.sol";

/// @title DiamondCutFacet
/// @author Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
contract OwnershipFacet is IERC173 {
    function transferOwnership(address newOwner) external override {
        LibFacetStorage.DiamondStorage storage ds = LibFacetStorage.diamondStorage();
        address currentOwner = ds.contractOwner;
        require(msg.sender == currentOwner, "Must own the contract.");
        ds.contractOwner = newOwner;
        emit OwnershipTransferred(currentOwner, newOwner);
    }

    function owner() external override view returns (address) {
        LibFacetStorage.DiamondStorage storage ds = LibFacetStorage.diamondStorage();
        return ds.contractOwner;
    }
}
