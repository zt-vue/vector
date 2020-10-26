// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import "./LibFacetStorage.sol";
import "../interfaces/IDiamondCut.sol";

/// @title LibDiamondCut
/// @author Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
library LibDiamondCut {
    event DiamondCut(IDiamondCut.Facet[] _diamondCut, address _init, bytes _calldata);

    // Non-standard internal function version of diamondCut
    // This code is almost the same as the external diamondCut,
    // except it is using 'Facet[] memory _diamondCut' instead of
    // 'Facet[] calldata _diamondCut'.
    // The code is duplicated to prevent copying calldata to memory which
    // causes an error for a two dimensional array.
    function diamondCut(IDiamondCut.Facet[] memory _diamondCut) internal {
        LibFacetStorage.DiamondStorage storage ds = LibFacetStorage.diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            selectorCount = addReplaceRemoveFacetSelectors(
                selectorCount,
                _diamondCut[facetIndex].facetAddress,
                _diamondCut[facetIndex].functionSelectors
            );
        }
        emit DiamondCut(_diamondCut, address(0), new bytes(0));
    }

    function addReplaceRemoveFacetSelectors(
        uint256 _selectorCount,
        address _newFacetAddress,
        bytes4[] memory _selectors
    ) internal returns (uint256) {
        LibFacetStorage.DiamondStorage storage ds = LibFacetStorage.diamondStorage();
        if (_newFacetAddress != address(0)) {
            hasContractCode(_newFacetAddress, "LibDiamondCut: facet has no code");
            // add and replace selectors
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                bytes4 selector = _selectors[selectorIndex];
                address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
                // add
                if (oldFacetAddress == address(0)) {
                    ds.facetAddressAndSelectorPosition[selector] = LibFacetStorage.FacetAddressAndSelectorPosition(
                        _newFacetAddress,
                        uint16(_selectorCount)
                    );
                    ds.selectors.push(selector);
                    _selectorCount++;
                } else {
                    // replace
                    require(oldFacetAddress != address(this), "LibDiamondCut: Can't replace immutable function");
                    if (oldFacetAddress != _newFacetAddress) {
                        // replace old facet address
                        ds.facetAddressAndSelectorPosition[selector].facetAddress = _newFacetAddress;
                    }
                }
            }
        } else {
            // remove functions
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                bytes4 selector = _selectors[selectorIndex];
                LibFacetStorage.FacetAddressAndSelectorPosition memory oldFacetAddressAndSelectorPosition = ds
                    .facetAddressAndSelectorPosition[selector];
                // if selector already does not exist then do nothing
                if (oldFacetAddressAndSelectorPosition.facetAddress == address(0)) {
                    continue;
                }
                require(oldFacetAddressAndSelectorPosition.facetAddress != address(this), "LibDiamondCut: Can't remove immutable function.");
                bytes4 lastSelector = ds.selectors[_selectorCount - 1];
                // replace selector with last selector
                if (oldFacetAddressAndSelectorPosition.selectorPosition != _selectorCount - 1) {
                    ds.selectors[oldFacetAddressAndSelectorPosition.selectorPosition] = lastSelector;
                    ds.facetAddressAndSelectorPosition[lastSelector].selectorPosition = oldFacetAddressAndSelectorPosition.selectorPosition;
                }
                // delete last selector
                ds.selectors.pop();
                delete ds.facetAddressAndSelectorPosition[selector];
                _selectorCount--;
            }
        }
        return _selectorCount;
    }

    function hasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}
