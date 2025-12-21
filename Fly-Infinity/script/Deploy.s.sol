// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/Script.sol";
import "../src/Fly_Infinity_Network.sol";
import "../src/Fly_Infinity_DAO.sol";

contract DeployNetwork is Script {
    bool mainnet = true;
    address[4] supportAddresses = mainnet
        ? [
            0x431430B832aa27d7807144ca4897A4d17215F259,
            0xe0fD852e3D3B24fD533122E67baFF95264172ef6,
            0xaaC6f3a4231c986d8dF1C3235859990041779060,
            0x61BbbAc4fc1F65C44ec99292115eF12A47083cd6
        ]
        : [address(1002), address(1004), address(1006), address(1008)];

    address founder = mainnet ? 0x101024cb50E169893d8Ad18f61F640e66c64e28b : 0x6Ac97c57138BD707680A10A798bAf24aCe62Ae9D; //change this
    address agent = 0xb54662c111c4aA206279a8cC046102588eC6D00f;
    address daiAddress =
        mainnet ? 0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3 : 0x320f0Ed6Fc42b0857e2b598B5DA85103203cf5d3; //cahnge this
    address oldContract = mainnet ?  0xd341197eE1171D30c0B1685b521C140A6299C200 : 0xEE107282dbe7235582E9D552BB77bEb5faDb1D76;

    function run() external {
        // 1. Start broadcasting transactions
        vm.startBroadcast();
        new Fly_Infinity_Network(founder, agent, daiAddress, oldContract, supportAddresses);
        vm.stopBroadcast();
    }
}
