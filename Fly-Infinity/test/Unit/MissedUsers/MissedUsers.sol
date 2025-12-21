// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Fly_Infinity_Network} from "../../../src/Fly_Infinity_Network.sol";
import {Smart_DeFi_NetWork} from "../../mocks/oldContractMock.sol";
import {DAI} from "../../mocks/DAI.sol";

contract ImportMechanismTest is Test {
    Fly_Infinity_Network sdn;
    Smart_DeFi_NetWork sdnOld;
    DAI dai;

    address[1] oldAddresses;
    address[1] newAddresses;
    address[4] supportAddresses;

    address founder = address(100);
    address agent = address(101);
    address bank = address(102);
    address founderWallet = address(103);
    address smartGift = address(104);
    address daiHolder = address(105);
    address root = address(106);

    address user1 = address(1);
    address user2 = address(2);
    address user3 = address(3);
    address user4 = address(4);
    address user5 = address(5);
    address user6 = address(6);
    address user7 = address(7);

    function setUp() public {
        dai = new DAI(daiHolder, type(uint256).max);
        sdnOld = new Smart_DeFi_NetWork(root, founder, address(dai), bank, founderWallet, smartGift, agent);
        registerOldUsers();
    }

    function fundDaiOld(address user) public {
        vm.prank(daiHolder);
        dai.transfer(user, 150e18);
        vm.prank(user);
        dai.approve(address(sdnOld), 150e18);
    }

    function registerOld(address user, address referrer) public {
        fundDaiOld(user);
        vm.startPrank(user);
        sdnOld.Agreement_Road_Map();
        sdnOld.BeCome_Owner(referrer);
        vm.stopPrank();
    }

    function fundDai(address user) public {
        vm.prank(daiHolder);
        dai.transfer(user, 150e18);
        vm.prank(user);
        dai.approve(address(sdn), 150e18);
    }

    function register(address user, address referrer) public {
        fundDai(user);
        vm.startPrank(user);
        sdn.Agreement_Road_Map();
        sdn.BeCome_Owner(referrer);
        vm.stopPrank();
    }

    function registerOldUsers() public {
        for (uint160 i = 1002; i < 1200; i++) {
            fundDaiOld(address(i));
        }

        registerOld(address(1002), root);
        registerOld(address(1003), root);

        for (uint160 i = 4; i < 200; i++) {
            uint160 id = i % 2 == 0 ? i / 2 : (i - 1) / 2;
            uint160 up = id + 1000;
            vm.startPrank(address(i + 1000));
            sdnOld.Agreement_Road_Map();
            sdnOld.BeCome_Owner(address(up));
            vm.stopPrank();
        }

        vm.warp(1 days + 1 hours);
        vm.prank(root);
        sdnOld.Reward();
    }

    function test_MissedUsers() public {
        registerOld(user1, address(1199));
        registerOld(user2, user1);
        registerOld(user3, user2);
        registerOld(user4, user3);

        address[] memory allUplines = sdnOld.Owner_UpLines_All_Address(user4);
        assertEq(allUplines[0], user3);
        assertEq(allUplines[1], user2);
        assertEq(allUplines[2], user1);
        assertEq(allUplines[3], address(1199));

        vm.warp(3 days + 2 hours);
        vm.prank(root);
        sdnOld.Reward();

        vm.prank(agent);
        sdnOld._Switch_Change();
        vm.prank(user1);
        sdnOld._Change_Wallet(address(2000));

        sdnOld.All_Owner_Address(0, 220);

        sdn = new Fly_Infinity_Network(founder, agent, address(dai), address(sdnOld), supportAddresses);
        sdn.Import_Batch(300);
        vm.stopPrank();

        assertFalse(sdn.Owner_Exists(user2));

        address[] memory allUplines2 = sdn.Owner_UpLines_All_Address(user4);

        vm.prank(user1);
        sdn.Import_Single(user2);

        assertTrue(sdn.Owner_Exists(user2));

        address[] memory allUplines3 = sdn.Owner_UpLines_All_Address(user4);
    }

    function test_MissedUserReward() public {
        registerOld(user1, address(1199));
        registerOld(user2, user1);
        registerOld(user3, user2);
        registerOld(user4, user2);
        registerOld(user5, user3);

        vm.warp(1 days + 3 hours);
        vm.prank(root);
        sdnOld.Reward();

        vm.prank(agent);
        sdnOld._Switch_Change();
        vm.prank(user1);
        sdnOld._Change_Wallet(address(2000));

        sdn = new Fly_Infinity_Network(founder, agent, address(dai), address(sdnOld), supportAddresses);
        sdn.Import_Batch(300);
        vm.stopPrank();

        register(user6, user3);
        register(user7, user4);

        // vm.prank(founder);
        // sdn.Import_Single(user2);

        vm.warp(1 days + 5 hours);
        vm.prank(address(1002));
        sdn.Reward();
    }
}
