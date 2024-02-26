// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/interface/interface.sol";
import "forge-std/console.sol";

interface IRUGGEDUNIV3POOL {
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sprtPriceLimitX96,
        bytes calldata data
    ) external;

    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}

interface IRUGGEDPROXY {
    struct UniversalRouterExecute {
        bytes commands;
        bytes[] inputs;
        uint256 deadline;
    }

    function claimReward() external;

    function targetedPurchase(
        uint256[] memory _tokenIds,
        UniversalRouterExecute calldata swapParam
    ) external payable;

    function unstake(uint256 _amount) external;

    function stake(uint256 _amount) external;
}
