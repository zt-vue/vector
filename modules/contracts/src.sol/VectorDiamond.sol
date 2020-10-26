// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

/******************************************************************************\
* Author: Nick Mudge
*
* Implementation of an example of a diamond.
/******************************************************************************/

import "./facets/DiamondCutFacet.sol";
import "./facets/OwnershipFacet.sol";
import "./interfaces/IDiamondCut.sol";
import "./interfaces/IVectorChannel.sol";
import "./lib/LibFacetStorage.sol";
import "./lib/LibFacetStorage.sol";
import "./lib/LibDiamondCut.sol";
import "./ReentrancyGuard.sol";

import "./AssetTransfer.sol";
import "./CMCAccountant.sol";
import "./CMCAdjudicator.sol";
import "./CMCDeposit.sol";
import "./CMCWithdraw.sol";

contract VectorDiamond is ReentrancyGuard {
    address constant invalidParticipant = address(1);

    address internal alice;
    address internal bob;

    // Prevents us from calling methods directly from the mastercopy contract
    modifier onlyViaProxy {
        require(alice != address(1), "Mastercopy: ONLY_VIA_PROXY");
        _;
    }

    /// @notice Contract constructor for Proxied copies
    /// @param _alice: Address representing user with function deposit
    /// @param _bob: Address representing user with multisig deposit
    function setup(address _alice, address _bob) external onlyViaProxy {
        ReentrancyGuard.setup();
        require(alice == address(0), "Channel has already been setup");
        require(_alice != address(0) && _bob != address(0), "Address zero not allowed as channel participant");
        require(_alice != _bob, "Channel participants must be different from each other");
        alice = _alice;
        bob = _bob;
    }

    /// @notice A getter function for the bob of the multisig
    /// @return Bob's signer address
    function getAlice() external view onlyViaProxy nonReentrantView returns (address) {
        return alice;
    }

    /// @notice A getter function for the bob of the multisig
    /// @return Alice's signer address
    function getBob() external view onlyViaProxy nonReentrantView returns (address) {
        return bob;
    }

    /// @notice Set invalid participants to block the mastercopy from being used directly
    ///         Nonzero address also prevents the mastercopy from being setup
    ///         Only setting alice is sufficient, setting bob too wouldn't change anything
    constructor () {
        alice = invalidParticipant;

        // LibFacetStorage.DiamondStorage storage ds = LibFacetStorage.diamondStorage();

        CMCAccountant accountant = new CMCAccountant();

        CMCAdjudicator adjudicator = new CMCAdjudicator();

        IDiamondCut.Facet[] memory diamondCut = new IDiamondCut.Facet[](3);

        // add CMCAccountant functions
        diamondCut[0].facetAddress = address(accountant);
        diamondCut[0].functionSelectors = new bytes4[](8);
        // from AssetTransfer
        diamondCut[0].functionSelectors[0] = AssetTransfer.getTotalTransferred.selector;
        diamondCut[0].functionSelectors[1] = AssetTransfer.getEmergencyWithdrawableAmount.selector;
        diamondCut[0].functionSelectors[2] = AssetTransfer.emergencyWithdraw.selector;
        // from CMCDeposit
        diamondCut[0].functionSelectors[3] = CMCDeposit.getTotalDepositsAlice.selector;
        diamondCut[0].functionSelectors[4] = CMCDeposit.getTotalDepositsBob.selector;
        diamondCut[0].functionSelectors[5] = CMCDeposit.depositAlice.selector;
        // from CMCWithdraw
        diamondCut[0].functionSelectors[6] = CMCWithdraw.getWithdrawalTransactionRecord.selector;
        diamondCut[0].functionSelectors[7] = CMCWithdraw.withdraw.selector;

        // add CMCAdjudicator functions
        diamondCut[1].facetAddress = address(adjudicator);
        diamondCut[1].functionSelectors = new bytes4[](6);
        diamondCut[1].functionSelectors[0] = CMCAdjudicator.getChannelDispute.selector;
        diamondCut[1].functionSelectors[1] = CMCAdjudicator.getTransferDispute.selector;
        diamondCut[1].functionSelectors[2] = CMCAdjudicator.disputeChannel.selector;
        diamondCut[1].functionSelectors[3] = CMCAdjudicator.defundChannel.selector;
        diamondCut[1].functionSelectors[4] = CMCAdjudicator.disputeTransfer.selector;
        diamondCut[1].functionSelectors[5] = CMCAdjudicator.defundTransfer.selector;

        // execute non-standard internal diamondCut function to add functions
        LibDiamondCut.diamondCut(diamondCut);

        /// adding ERC165 data
        /// ERC165
        // ds.supportedInterfaces[IERC165.supportsInterface.selector] = true;
        /// DiamondCut
        // ds.supportedInterfaces[IDiamondCut.diamondCut.selector] = true;
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibFacetStorage.DiamondStorage storage ds;
        bytes32 position = LibFacetStorage.DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
        address facet = address(bytes20(ds.facetAddressAndSelectorPosition[msg.sig].facetAddress));
        require(facet != address(0), "Diamond: Function does not exist");
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }

    receive() external payable {}
}
