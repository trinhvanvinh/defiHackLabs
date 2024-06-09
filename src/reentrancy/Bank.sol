//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/utils/Address.sol";
import "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

contract Bank is ReentrancyGuard {
    using Address for address;

    mapping(address => uint256) public balanceOf;

    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
    }

    function withdraw() external nonReentrant {
        uint256 depositAmount = balanceOf[msg.sender];
        (bool sent, ) = msg.sender.call{value: balanceOf[msg.sender]}("");
        balanceOf[msg.sender] = 0;
    }
}
