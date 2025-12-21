// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Fly_Infinity_Network} from "../../../src/Fly_Infinity_Network.sol";
import {Smart_DeFi_NetWork} from "../../mocks/oldContractMock.sol";
import {Fly_Infinity_Gift} from "../../../src/Fly_Infinity_Gift.sol";
import {Fly_Infinity_Token} from "../../../src/Fly_Infinity_Token.sol";
import {DAI} from "../../mocks/DAI.sol";

contract Networ2kMechanismTest is Test {
    Fly_Infinity_Network sdn;
    Smart_DeFi_NetWork sdnOld;
    Fly_Infinity_Gift giftContract;
    Fly_Infinity_Token bankContract;
    DAI dai;

    address[1] oldAddresses;
    address[1] newAddresses;
    address[4] supportAddresses = [address(1199), address(1198), address(1197), address(1196)];

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

    function setUp() public {
        dai = new DAI(daiHolder, type(uint256).max);
        sdnOld = new Smart_DeFi_NetWork(root, founder, address(dai), bank, founderWallet, smartGift, agent);
        registerOldUsers();

        // Get references to deployed contracts
        giftContract = sdn.Fly_Infinity_Gift_Contract();
        bankContract = sdn.Fly_Infinity_Token_Contract();
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
        sdn = new Fly_Infinity_Network(founder, agent, address(dai), address(sdnOld), supportAddresses);
        sdn.Import_Batch(300);
        vm.stopPrank();
    }

    function test_Support() public {
        register(user1, address(1199));
        register(user2, address(1199));
        vm.assertEq(sdn.Owner_Info_Global(address(1199)).LT, 1);
        vm.assertEq(sdn.Owner_Info_Global(address(1199)).RT, 1);

        uint256 bal1 = dai.balanceOf(address(1199));
        uint256 bal1Bank = dai.balanceOf(address(sdn.Fly_Infinity_Token_Contract()));
        vm.warp(5 days + 1 hours);
        vm.prank(root);
        sdn.Reward();
        uint256 bal2 = dai.balanceOf(address(1199));
        uint256 bal2Bank = dai.balanceOf(address(sdn.Fly_Infinity_Token_Contract()));

        uint256 lastPointValue = sdn.Last_Value_Point();
        assertEq(bal2 - bal1, 0);
        assertApproxEqAbs(bal2Bank - bal1Bank, lastPointValue * 1e18 + 6e18, 1e18);
    }

    function test_ChangeWalletSupport() public {
        register(user1, address(1199));
        register(user2, address(1199));
        vm.assertEq(sdn.Owner_Info_Global(address(1199)).LT, 1);
        vm.assertEq(sdn.Owner_Info_Global(address(1199)).RT, 1);

        uint256 bal1 = dai.balanceOf(address(1199));
        uint256 bal1Bank = dai.balanceOf(address(sdn.Fly_Infinity_Token_Contract()));
        vm.warp(5 days + 1 hours);
        vm.prank(root);
        sdn.Reward();
        uint256 bal2 = dai.balanceOf(address(1199));
        uint256 bal2Bank = dai.balanceOf(address(sdn.Fly_Infinity_Token_Contract()));

        uint256 lastPointValue = sdn.Last_Value_Point();
        assertEq(bal2 - bal1, 0);
        assertApproxEqAbs(bal2Bank - bal1Bank, lastPointValue * 1e18 + 6e18, 1e18);

        vm.prank(address(1199));
        sdn._Change_Wallet(address(2199));

        register(user3, user1);
        register(user4, user2);

        uint256 bal1Old = dai.balanceOf(address(1199));
        uint256 bal3 = dai.balanceOf(address(2199));
        uint256 bal3Bank = dai.balanceOf(address(sdn.Fly_Infinity_Token_Contract()));
        vm.warp(5 days + 3 hours);
        vm.prank(root);
        sdn.Reward();
        uint256 bal2Old = dai.balanceOf(address(1199));
        uint256 bal4 = dai.balanceOf(address(2199));
        uint256 bal4Bank = dai.balanceOf(address(sdn.Fly_Infinity_Token_Contract()));

        uint256 lastPointValue2 = sdn.Last_Value_Point();
        assertEq(bal4 - bal3, 0);
        assertEq(bal2Old - bal1Old, 0);
        assertApproxEqAbs(bal4Bank - bal3Bank, lastPointValue2 * 1e18 + 6e18, 1e18);
    }
}
