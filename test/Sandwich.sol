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
        deal(victim, 1_000 * 1e18 ether);
        deal(address(attacker), 1_000 * 1e18 ether);
    }
}
