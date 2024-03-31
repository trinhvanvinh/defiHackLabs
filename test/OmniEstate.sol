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
    IWBNB WBNB = IWBNB(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
}
