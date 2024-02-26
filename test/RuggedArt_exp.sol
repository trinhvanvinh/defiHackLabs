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

interface IRUGGED is IERC20{
    function getTokenIdPool() external view returns(uint256[] memory);
    function ownerOf(uint256 id) external view returns(address owner);
}

interface IWeth is IERC20{}

contract ContractTest is Test{
     IRUGGEDUNIV3POOL pool = IRUGGEDUNIV3POOL(0x99147452078fa5C6642D3E5F7efD51113A9527a5);
    IRUGGEDPROXY proxy = IRUGGEDPROXY(0x2648f5592c09a260C601ACde44e7f8f2944944Fb);
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
        cheats.label(address(0xFe380fe1DB07e531E3519b9AE3EA9f7888CE20C6), "RuggedMarket");
        cheats.label(address(0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD), "Universal_Router");
     }

         function onERC721Received(address, address, uint256, bytes memory) public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    fallback() external payable{

    }

    function testExploit() public{
        console.log("WETH: ", WETH.balanceOf(address(this)));
        payable(address(0)).transfer(WETH.balanceOf(address(this)));
    }

}