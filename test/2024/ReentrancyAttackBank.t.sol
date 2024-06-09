// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import {Bank} from "../../src/reentrancy/Bank.sol";
import {AttackBank} from "../../src/reentrancy/AttackBank.sol";

contract ReentrancyAttackBankTest is Test {
    Bank public bank;
    AttackBank public attackBank;
    address public INNOCENT = vm.addr(0x01);
    address public ATTACKER = vm.addr(0x02);

    function setUp() public {
        bank = new Bank();
        attackBank = new AttackBank(address(bank));
        vm.deal(INNOCENT, 10 ether);
        vm.deal(ATTACKER, 2 ether);
    }

    function testInnocentTransfer() public {
        vm.startPrank(INNOCENT);
        console2.log("1 ", address(bank).balance);
        bank.deposit{value: 10 ether}();
        //vm.stopPrank();
        console2.log("bank ", address(bank).balance);
        vm.startPrank(ATTACKER);
        console2.log("attacker ", address(bank).balance);
        attackBank.attack{value: 1 ether}();
        //msg.sender.call{value: address(attackBank).balance}("");
        console2.log("bank2 ", address(bank).balance);
        console2.log("attacker2 ", address(attackBank).balance);
        //msg.sender.call{value: address(attackBank).balance}("");
        console2.log("bank2 ", address(msg.sender).balance);
        console2.log("attacker2 ", address(attackBank).balance);
    }
}
