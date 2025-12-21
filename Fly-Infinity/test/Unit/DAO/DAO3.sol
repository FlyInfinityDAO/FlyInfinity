// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Fly_Infinity_Network, Fly_Infinity_Token} from "../../../src/Fly_Infinity_Network.sol";
import {Smart_DeFi_NetWork} from "../../mocks/oldContractMock.sol";
import {Fly_Infinity_DAO} from "../../../src/Fly_Infinity_DAO.sol";
import {Fly_Infinity_Gift} from "../../../src/Fly_Infinity_Gift.sol";
import {MockDeFi} from "./mocks/MockNetwork.sol";
import {MockGift} from "./mocks/MockGift.sol";
import {MockToken} from "./mocks/MockToken.sol";
import {DAI} from "../../mocks/DAI.sol";

contract DAO2MechanismTest is Test {
    Fly_Infinity_Network sdn;
    Smart_DeFi_NetWork sdnOld;
    Fly_Infinity_DAO dao;
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
        sdn = new Fly_Infinity_Network(founder, agent, address(dai), address(sdnOld), supportAddresses);
        dao = sdn.Fly_Infinity_DAO_Contract();
        vm.startPrank(founder);
        sdn.Import_Batch(300);
        vm.stopPrank();
    }

    function test_OldContractCanStillBeCallable() public {
        MockDeFi newNetwork = new MockDeFi(founder, address(dao));

        vm.prank(founder);
        dao.Propose_Network_Address_Change(address(newNetwork));

        // Get enough positive votes
        for (uint160 i = 1002; i < 1010; i++) {
            vm.prank(address(i));
            dao.Vote(true);
        }

        // Add one negative vote
        vm.prank(address(1010));
        dao.Vote(false);

        // Fast forward past voting period
        vm.warp(block.timestamp + 3 days + 1);

        // Execute proposal
        dao.Execute_Proposal();

        register(user2, address(1199));
        sdn.Owner_Info_Classic(user2);

        vm.warp(block.timestamp + 1 hours);
        vm.prank(root);
        sdn.Reward();
    }
}
