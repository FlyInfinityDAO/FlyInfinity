// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DAI is ERC20 {
    constructor(address user, uint256 supply) ERC20("DAI Stable Coin", "DAI") {
        _mint(user, supply);
    }
}
