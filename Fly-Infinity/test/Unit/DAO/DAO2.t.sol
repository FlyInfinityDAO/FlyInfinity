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

    function test_Critical_RapidProposalCreationAndExecution() public {
        for (uint256 i = 0; i < 5; i++) {
            MockDeFi newNetwork = new MockDeFi(founder, address(dao));

            vm.prank(founder);
            dao.Propose_Network_Address_Change(address(newNetwork));

            // Quick vote
            for (uint160 j = 1002; j < 1010; j++) {
                vm.prank(address(j));
                dao.Vote(true);
            }

            vm.warp(block.timestamp + 7 days + 1);
            dao.Execute_Proposal();

            vm.warp(block.timestamp + 1);
        }

        assertFalse(dao.Has_Active_Proposal());
    }

    function test_Critical_VoteIntegrityAcrossProposals() public {
        MockDeFi newNetwork1 = new MockDeFi(founder, address(dao));
        MockDeFi newNetwork2 = new MockDeFi(founder, address(dao));

        // First proposal
        vm.prank(founder);
        dao.Propose_Network_Address_Change(address(newNetwork1));

        vm.prank(address(1002));
        dao.Vote(true);

        vm.warp(block.timestamp + 7 days + 1);
        dao.Execute_Proposal();

        // Second proposal
        vm.warp(block.timestamp + 1);
        vm.prank(founder);
        dao.Propose_Network_Address_Change(address(newNetwork2));

        // Same user should be able to vote again
        vm.prank(address(1002));
        dao.Vote(false); // Different vote

        // Verify votes are separate
        assertTrue(dao.Has_Voted_On_Proposal(1, address(1002)));
        assertTrue(dao.Has_Voted_On_Proposal(2, address(1002)));
        assertTrue(dao.Get_Vote_Choice_On_Proposal(1, address(1002))); // true on first
        assertFalse(dao.Get_Vote_Choice_On_Proposal(2, address(1002))); // false on second
    }

    function test_Critical_MultipleSequentialProposalsWithDifferentTypes() public {
        address newNetwork = address(new MockDeFi(founder, address(dao)));
        address newGift = address(new MockGift(founder, address(dao)));
        address anotherNetwork = address(new MockDeFi(founder, address(dao)));

        // First: Network change
        vm.prank(founder);
        dao.Propose_Network_Address_Change(newNetwork);

        for (uint160 i = 1002; i < 1010; i++) {
            vm.prank(address(i));
            dao.Vote(true);
        }

        vm.warp(block.timestamp + 7 days + 1);
        dao.Execute_Proposal();

        // Second: Gift change
        vm.warp(block.timestamp + 1);
        vm.prank(founder);
        dao.Propose_Gift_Address_Change(newGift);

        for (uint160 i = 1002; i < 1010; i++) {
            vm.prank(address(i));
            dao.Vote(false); // Reject this one
        }

        vm.warp(block.timestamp + 7 days + 1);
        dao.Execute_Proposal();

        // Third: Another network change
        vm.warp(block.timestamp + 1);
        vm.prank(founder);
        dao.Propose_Network_Address_Change(anotherNetwork);

        // Verify we can create third proposal
        assertTrue(dao.Has_Active_Proposal());
    }

    function test_ChangeGift() public {
        address oldGift = address(sdn.Fly_Infinity_Gift_Contract());
        uint256 balGift1 = dai.balanceOf(oldGift);
        register(user1, address(1199));
        uint256 balGift2 = dai.balanceOf(oldGift);
        assertEq(balGift2 - balGift1, 5e18);

        address newGift = address(new MockGift(founder, address(dao)));
        vm.prank(founder);
        dao.Propose_Gift_Address_Change(newGift);

        for (uint160 i = 1002; i < 1010; i++) {
            vm.prank(address(i));
            dao.Vote(true);
        }
        vm.warp(block.timestamp + 7 days + 1);
        dao.Execute_Proposal();

        assertEq(address(sdn.Fly_Infinity_Gift_Contract()), newGift);

        uint256 balGiftnew1 = dai.balanceOf(newGift);
        uint256 balGiftold1 = dai.balanceOf(oldGift);
        register(user2, address(1199));
        uint256 balGiftnew2 = dai.balanceOf(newGift);
        uint256 balGiftold2 = dai.balanceOf(oldGift);
        assertEq(balGiftnew2 - balGiftnew1, 5e18);
        assertEq(balGiftold2 - balGiftold1, 0);
    }

    function test_ChangeNetwork() public {
        assertEq(address(sdn.Fly_Infinity_Token_Contract().Fly_Infinity_Network_Contract()), address(sdn));
        assertEq(address(dao.Fly_Infinity_Network_Contract()), address(sdn));

        fundDai(user1);
        vm.startPrank(user1);
        dai.approve(address(sdn.Fly_Infinity_Token_Contract()), 1000e18);
        Fly_Infinity_Token bankContract = sdn.Fly_Infinity_Token_Contract();
        vm.expectRevert("Only Networker");
        bankContract.Buy(address(this), 100e18);
        vm.stopPrank();

        MockDeFi newDeFiContract = new MockDeFi(founder, address(dao));
        address newDeFiAddress = address(newDeFiContract);

        vm.prank(founder);
        dao.Propose_Network_Address_Change(newDeFiAddress);

        for (uint160 i = 1002; i < 1010; i++) {
            vm.prank(address(i));
            dao.Vote(true);
        }
        vm.warp(block.timestamp + 7 days + 1);
        dao.Execute_Proposal();

        assertEq(address(sdn.Fly_Infinity_Token_Contract().Fly_Infinity_Network_Contract()), newDeFiAddress);
        assertEq(address(dao.Fly_Infinity_Network_Contract()), newDeFiAddress);

        vm.startPrank(user1);
        bankContract.Buy(user1, 100e18);
        vm.stopPrank();
    }

    function test_ChangeCycle() public {
        address oldGift = address(sdn.Fly_Infinity_Gift_Contract());
        uint256 balGift1 = dai.balanceOf(oldGift);
        register(user1, address(1199));
        uint256 balGift2 = dai.balanceOf(oldGift);
        assertEq(balGift2 - balGift1, 5e18);

        address newGift = address(new MockGift(founder, address(dao)));
        vm.prank(founder);
        dao.Propose_Gift_Address_Change(newGift);

        for (uint160 i = 1002; i < 1010; i++) {
            vm.prank(address(i));
            dao.Vote(true);
        }
        vm.warp(block.timestamp + 7 days + 1);
        dao.Execute_Proposal();

        assertEq(address(sdn.Fly_Infinity_Gift_Contract()), newGift);

        uint256 balGiftnew1 = dai.balanceOf(newGift);
        uint256 balGiftold1 = dai.balanceOf(oldGift);
        register(user2, address(1199));
        uint256 balGiftnew2 = dai.balanceOf(newGift);
        uint256 balGiftold2 = dai.balanceOf(oldGift);
        assertEq(balGiftnew2 - balGiftnew1, 5e18);
        assertEq(balGiftold2 - balGiftold1, 0);

        assertEq(address(sdn.Fly_Infinity_Token_Contract().Fly_Infinity_Network_Contract()), address(sdn));
        assertEq(address(dao.Fly_Infinity_Network_Contract()), address(sdn));

        fundDai(user3);
        vm.startPrank(user3);
        dai.approve(address(sdn.Fly_Infinity_Token_Contract()), 1000e18);
        Fly_Infinity_Token bankContract = sdn.Fly_Infinity_Token_Contract();
        vm.expectRevert("Only Networker");
        bankContract.Buy(address(this), 100e18);
        vm.stopPrank();

        MockDeFi newDeFiContract = new MockDeFi(founder, address(dao));
        address newDeFiAddress = address(newDeFiContract);

        vm.prank(founder);
        dao.Propose_Network_Address_Change(newDeFiAddress);

        for (uint160 i = 1002; i < 1010; i++) {
            vm.prank(address(i));
            dao.Vote(true);
        }
        vm.warp(block.timestamp + 7 days + 1);
        dao.Execute_Proposal();

        assertEq(address(sdn.Fly_Infinity_Token_Contract().Fly_Infinity_Network_Contract()), newDeFiAddress);
        assertEq(address(dao.Fly_Infinity_Network_Contract()), newDeFiAddress);

        vm.startPrank(user3);
        bankContract.Buy(user3, 100e18);
        vm.stopPrank();

        address newGift2 = address(new MockGift(founder, address(dao)));

        vm.prank(founder);
        dao.Propose_Gift_Address_Change(newGift2);

        for (uint160 i = 1002; i < 1010; i++) {
            vm.prank(address(i));
            dao.Vote(true);
        }
        assertEq(address(newDeFiContract.Fly_Infinity_Gift_()), address(0));

        vm.warp(block.timestamp + 7 days + 1);
        dao.Execute_Proposal();

        assertEq(address(newDeFiContract.Fly_Infinity_Gift_()), newGift2);
        assertEq(address(sdn.Fly_Infinity_Gift_Contract()), newGift);
    }

    function test_Migration_Execute_Proposal_MovesNetworkFunds() public {
        MockDeFi newNetwork = new MockDeFi(founder, address(dao));

        // Ensure the current network holds some DAI that should be migrated
        fundDai(user1);
        register(user1, address(1199));
        uint256 initialNetworkBalance = dai.balanceOf(address(sdn));
        assertGt(initialNetworkBalance, 0, "Network should hold DAI before migration");

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

        assertFalse(dao.Has_Active_Proposal());

        // Check proposal status
        (,,,,,,,, Fly_Infinity_DAO.ProposalStatus status) = dao.Get_Proposal(1);
        assertEq(uint256(status), uint256(Fly_Infinity_DAO.ProposalStatus.Executed));

        // Verify funds migrated from old Network to new Network address
        assertEq(dai.balanceOf(address(sdn)), 0, "Old network should have no DAI after migration");
        assertEq(
            dai.balanceOf(address(newNetwork)),
            initialNetworkBalance,
            "New network address should receive all DAI from old network"
        );
    }

    function test_Migration_ExecuteGiftAddressChange_MovesGiftFunds() public {
        // Ensure current gift holds some DAI that will be migrated
        fundDai(user1);
        register(user1, address(1199));

        address oldGift = address(sdn.Fly_Infinity_Gift_Contract());
        uint256 initialGiftBalance = dai.balanceOf(oldGift);
        assertGt(initialGiftBalance, 0, "Gift should hold DAI before migration");

        // Deploy a new Gift contract that will act as the upgrade target
        Fly_Infinity_Gift newGift = new Fly_Infinity_Gift(founder, address(dai), address(sdn));

        // Propose gift address change
        vm.prank(founder);
        dao.Propose_Gift_Address_Change(address(newGift));

        // Have some networkers vote positively so proposal passes
        for (uint160 i = 1002; i < 1010; i++) {
            vm.prank(address(i));
            dao.Vote(true);
        }

        // Fast forward past voting period
        vm.warp(block.timestamp + 3 days + 1);

        // Execute proposal
        dao.Execute_Proposal();

        // Check proposal status
        (,,,,,,,, Fly_Infinity_DAO.ProposalStatus statusGift) = dao.Get_Proposal(1);
        assertEq(uint256(statusGift), uint256(Fly_Infinity_DAO.ProposalStatus.Executed));

        // Verify funds migrated from old Gift to new Gift
        assertEq(dai.balanceOf(oldGift), 0, "Old gift should have no DAI after migration");
        assertEq(dai.balanceOf(address(newGift)), initialGiftBalance, "New gift should receive all DAI from old gift");
    }
}
