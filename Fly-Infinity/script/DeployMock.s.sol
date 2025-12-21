// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "../test/Testnet/Mock/MockSmartDeFi.sol";
import {Script} from "forge-std/Script.sol";

contract DeployNetwork is Script {
    function run() external {
        // 1. Start broadcasting transactions
        vm.startBroadcast();

        new MockContract();
        vm.stopBroadcast();
    }
}
