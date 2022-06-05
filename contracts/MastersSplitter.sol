//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract MastersSplitter is PaymentSplitter {
    constructor(address[] memory payees, uint256[] memory shares)
        PaymentSplitter(payees, shares)
    {}
}
