// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import "./interfaces/ICMCWithdraw.sol";
import "./CMCCore.sol";
import "./AssetTransfer.sol";
import "./lib/LibAsset.sol";
import "./lib/LibChannelCrypto.sol";
import "./lib/LibUtils.sol";

contract CMCWithdraw is CMCCore, AssetTransfer, ICMCWithdraw {
  using LibChannelCrypto for bytes32;

  mapping(bytes32 => bool) private isExecuted;

  /// @param recipient The address to which we're withdrawing funds to
  /// @param assetId The token address of the asset we're withdrawing (address(0)=eth)
  /// @param maxAmount The number of units of asset we're withdrawing
  /// @param aliceSignature Signature of owner a
  /// @param bobSignature Signature of owner b
  function withdraw(
    address payable recipient,
    address assetId,
    uint256 maxAmount,
    uint256 nonce,
    bytes memory aliceSignature,
    bytes memory bobSignature
  ) external override onlyViaProxy nonReentrant {
    // Replay protection
    bytes32 withdrawHash = keccak256(abi.encodePacked(recipient, assetId, maxAmount, nonce));
    require(!isExecuted[withdrawHash], "CMCWithdraw: Transaction has already been executed");
    isExecuted[withdrawHash] = true;

    // Validate signatures
    require(withdrawHash.checkSignature(aliceSignature, alice), "CMCWithdraw: Invalid alice signature");
    require(withdrawHash.checkSignature(bobSignature, bob), "CMCWithdraw: Invalid bob signature");

    // Determine actually transferable amount
    uint256 balance = LibAsset.getOwnBalance(assetId);
    uint256 amount = LibUtils.min(maxAmount, balance);

    // Add to totalWithdrawn
    registerTransfer(assetId, amount);

    // Execute the withdraw
    require(LibAsset.transfer(assetId, recipient, amount), "CMCWithdraw: Transfer failed");
  }

  function getWithdrawalTransactionRecord(
    address recipient,
    address assetId,
    uint256 amount,
    uint256 nonce
  ) external override view onlyViaProxy nonReentrantView returns (bool) {
    bytes32 withdrawHash = keccak256(abi.encodePacked(recipient, assetId, amount, nonce));
    return isExecuted[withdrawHash];
  }
}
