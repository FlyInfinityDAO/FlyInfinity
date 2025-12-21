// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.24;

// import {Test} from "forge-std/Test.sol";
// import {console} from "forge-std/console.sol";
// import {Fly_Infinity_Network} from "../../src/Fly_Infinity_Network.sol";
// import {MockContract} from "./Mock/MockSmartDeFi.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// interface INetwork {
//     function Agreement_Road_Map() external;
//     function BeCome_Owner(address) external;
//     function Reward() external;
//     function Owner_Info_Classic(address owner)
//         external
//         view
//         returns (
//             uint64 ID,
//             uint32 All_Left,
//             uint32 All_Right,
//             uint32 Left,
//             uint32 Right,
//             address UpLine_Address,
//             address Left_Address,
//             address Right_Address
//         );
// }

// contract TestnetTest is Test {
//     INetwork network;

//     function setUp() public {
//         network = INetwork(0x0306718E2eC6A7dFe49207e2F03AFA2566881549);
//     }

//     function test_Testnet_Test() public {
//         // vm.startPrank(0xa44933EB3c11c239DFf2df693E8934ad6b642a9c);
//         // // network.Agreement_Road_Map();
//         // network.BeCome_Owner(address(1080));
//         // vm.stopPrank();

//         // vm.startPrank(0xaCF0A09C372293b59A5603D1eA1D9508ab55F30A);
//         // network.Agreement_Road_Map();
//         // network.BeCome_Owner(address(0x0000000000000000000000000000000000000442));
//         // vm.stopPrank();

//         network.Owner_Info_Classic(address(0xa44933EB3c11c239DFf2df693E8934ad6b642a9c));

//         vm.prank(address(1002));
//         network.Reward();
//     }
// }
