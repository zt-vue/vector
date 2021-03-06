// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import "./Types.sol";

interface ICMCDeposit {
  function getTotalDepositsAlice(address assetId) external view returns (uint256);

  function getTotalDepositsBob(address assetId) external view returns (uint256);

  function depositAlice(
    address assetId,
    uint256 amount
    // bytes memory signature
  ) external payable;
}
