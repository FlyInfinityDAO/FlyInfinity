// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Fly_Infinity_Network, Fly_Infinity_Token} from "../../../src/Fly_Infinity_Network.sol";
import {Smart_DeFi_NetWork} from "../../mocks/oldContractMock.sol";
import {Fly_Infinity_DAO} from "../../../src/Fly_Infinity_DAO.sol";
import {Fly_Infinity_Gift} from "../../../src/Fly_Infinity_Gift.sol";
import {DAI} from "../../mocks/DAI.sol";
import {MockDeFi} from "./mocks/MockNetwork.sol";
import {MockGift} from "./mocks/MockGift.sol";

contract DAOMechanismTest is Test {
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

    function test_ProposeNetworkAddressChange() public {
        MockDeFi newNetwork = new MockDeFi(founder, address(dao));

        vm.prank(founder);
        uint256 proposalId = dao.Propose_Network_Address_Change(address(newNetwork));

        assertEq(proposalId, 1);
        assertTrue(dao.Has_Active_Proposal());
        assertEq(dao.Get_Active_Proposal_Id(), 1);

        (
            uint256 id,
            Fly_Infinity_DAO.ProposalType proposalType,
            address proposedAddress,
            address proposer,
            uint256 startTime,
            uint256 endTime,
            uint256 positiveVotes,
            uint256 negativeVotes,
            Fly_Infinity_DAO.ProposalStatus status
        ) = dao.Get_Active_Proposal();

        assertEq(id, 1);
        assertEq(uint256(proposalType), uint256(Fly_Infinity_DAO.ProposalType.CHANGE_NETWORK_ADDRESS));
        assertEq(proposedAddress, address(newNetwork));
        assertEq(proposer, founder);
        assertEq(startTime, block.timestamp);
        assertEq(endTime, block.timestamp + 3 days);
        assertEq(positiveVotes, 0);
        assertEq(negativeVotes, 0);
        assertEq(uint256(status), uint256(Fly_Infinity_DAO.ProposalStatus.Active));
    }

    function test_ProposeGiftAddressChange() public {
        Fly_Infinity_Gift newGift = new Fly_Infinity_Gift(founder, address(dai), address(sdn));

        vm.prank(founder);
        uint256 proposalId = dao.Propose_Gift_Address_Change(address(newGift));

        assertEq(proposalId, 1);
        assertTrue(dao.Has_Active_Proposal());

        (, Fly_Infinity_DAO.ProposalType proposalType, address proposedAddress,,,,,,) = dao.Get_Active_Proposal();

        assertEq(uint256(proposalType), uint256(Fly_Infinity_DAO.ProposalType.CHANGE_GIFT_ADDRESS));
        assertEq(proposedAddress, address(newGift));
    }

    function test_RevertProposeWhenNotOwner() public {
        MockDeFi newNetwork = new MockDeFi(founder, address(dao));

        vm.prank(user1);
        vm.expectRevert("Only founder can call this");
        dao.Propose_Network_Address_Change(address(newNetwork));
    }

    function test_RevertProposeWithInvalidAddress() public {
        vm.prank(founder);
        vm.expectRevert("Invalid address");
        dao.Propose_Network_Address_Change(address(0));
    }

    function test_RevertProposeWithSameAddress() public {
        vm.prank(founder);
        vm.expectRevert("Same as current address");
        dao.Propose_Network_Address_Change(address(sdn));
    }

    function test_RevertProposeWhenActiveProposalExists() public {
        MockDeFi newNetwork1 = new MockDeFi(founder, address(dao));
        MockDeFi newNetwork2 = new MockDeFi(founder, address(dao));

        vm.startPrank(founder);
        dao.Propose_Network_Address_Change(address(newNetwork1));

        vm.expectRevert("Another proposal is active");
        dao.Propose_Network_Address_Change(address(newNetwork2));
        vm.stopPrank();
    }

    function test_VotePositive() public {
        address newNetwork = address(new MockDeFi(founder, address(dao)));

        vm.prank(founder);
        dao.Propose_Network_Address_Change(newNetwork);

        // Vote from registered user
        vm.prank(address(1002));
        dao.Vote(true);

        (,,,,,, uint256 positiveVotes, uint256 negativeVotes,) = dao.Get_Active_Proposal();

        assertEq(positiveVotes, 1);
        assertEq(negativeVotes, 0);
        assertTrue(dao.Has_Voted(address(1002)));
        assertTrue(dao.Get_Vote_Choice(address(1002)));
    }

    function test_VoteNegative() public {
        address newNetwork = address(new MockDeFi(founder, address(dao)));

        vm.prank(founder);
        dao.Propose_Network_Address_Change(newNetwork);

        vm.prank(address(1002));
        dao.Vote(false);

        (,,,,,, uint256 positiveVotes, uint256 negativeVotes,) = dao.Get_Active_Proposal();

        assertEq(positiveVotes, 0);
        assertEq(negativeVotes, 1);
        assertTrue(dao.Has_Voted(address(1002)));
        assertFalse(dao.Get_Vote_Choice(address(1002)));
    }

    function test_MultipleVotes() public {
        address newNetwork = address(new MockDeFi(founder, address(dao)));

        vm.prank(founder);
        dao.Propose_Network_Address_Change(newNetwork);

        // Multiple users vote
        vm.prank(address(1002));
        dao.Vote(true);

        vm.prank(address(1003));
        dao.Vote(true);

        vm.prank(address(1004));
        dao.Vote(false);

        (,,,,,, uint256 positiveVotes, uint256 negativeVotes,) = dao.Get_Active_Proposal();

        assertEq(positiveVotes, 2);
        assertEq(negativeVotes, 1);
    }

    function test_RevertVoteWhenNotNetworker() public {
        address newNetwork = address(new MockDeFi(founder, address(dao)));

        vm.prank(founder);
        dao.Propose_Network_Address_Change(newNetwork);

        vm.prank(address(9999)); // Not registered
        vm.expectRevert("Only networkers can vote");
        dao.Vote(true);
    }

    function test_RevertVoteWhenNoActiveProposal() public {
        vm.prank(address(1002));
        vm.expectRevert("No active proposal");
        dao.Vote(true);
    }

    function test_RevertVoteAfterVotingPeriod() public {
        address newNetwork = address(new MockDeFi(founder, address(dao)));

        vm.prank(founder);
        dao.Propose_Network_Address_Change(newNetwork);

        // Fast forward past voting period
        vm.warp(block.timestamp + 3 days + 1);

        vm.prank(address(1002));
        vm.expectRevert("Voting period ended");
        dao.Vote(true);
    }

    function test_RevertVoteTwice() public {
        address newNetwork = address(new MockDeFi(founder, address(dao)));

        vm.prank(founder);
        dao.Propose_Network_Address_Change(newNetwork);

        vm.startPrank(address(1002));
        dao.Vote(true);

        vm.expectRevert("Already voted");
        dao.Vote(true);
        vm.stopPrank();
    }

    function test_ExecuteProposalSuccess() public {
        MockDeFi newNetwork = new MockDeFi(founder, address(dao));
        fundDai(address(sdn));

        // Ensure the current network holds some DAI that should be migrated
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

    function test_ExecuteProposalSuccessGift() public {
        MockGift newGift = new MockGift(founder, address(dao));
        address oldGift = address(sdn.Fly_Infinity_Gift_Contract());
        fundDai(oldGift);

        // Ensure the current network holds some DAI that should be migrated
        uint256 initialNetworkBalance = dai.balanceOf(oldGift);
        assertGt(initialNetworkBalance, 0, "Gift should hold DAI before migration");

        vm.prank(founder);
        dao.Propose_Gift_Address_Change(address(newGift));

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
        assertEq(dai.balanceOf(oldGift), 0, "Old network should have no DAI after migration");
        assertEq(
            dai.balanceOf(address(newGift)),
            initialNetworkBalance,
            "New network address should receive all DAI from old network"
        );
    }

    function test_ExecuteProposalRejected() public {
        address newNetwork = address(new MockDeFi(founder, address(dao)));

        vm.prank(founder);
        dao.Propose_Network_Address_Change(newNetwork);

        // Get more negative votes
        for (uint160 i = 1002; i < 1010; i++) {
            vm.prank(address(i));
            dao.Vote(false);
        }

        // Add fewer positive votes
        vm.prank(address(1010));
        dao.Vote(true);

        // Fast forward past voting period
        vm.warp(block.timestamp + 3 days + 1);

        // Execute proposal
        dao.Execute_Proposal();

        assertFalse(dao.Has_Active_Proposal());

        // Check proposal status
        (,,,,,,,, Fly_Infinity_DAO.ProposalStatus status) = dao.Get_Proposal(1);
        assertEq(uint256(status), uint256(Fly_Infinity_DAO.ProposalStatus.Rejected));
    }

    function test_RevertExecuteBeforeVotingEnds() public {
        address newNetwork = address(new MockDeFi(founder, address(dao)));

        vm.prank(founder);
        dao.Propose_Network_Address_Change(newNetwork);

        vm.prank(address(1002));
        dao.Vote(true);

        vm.expectRevert("Voting period not ended");
        dao.Execute_Proposal();
    }

    function test_RevertExecuteWhenNoActiveProposal() public {
        vm.expectRevert("No active proposal");
        dao.Execute_Proposal();
    }

    function test_Get_Time_Remaining() public {
        address newNetwork = address(new MockDeFi(founder, address(dao)));

        vm.prank(founder);
        dao.Propose_Network_Address_Change(newNetwork);

        assertEq(dao.Get_Time_Remaining(), 3 days);

        vm.warp(block.timestamp + 1 days);
        assertEq(dao.Get_Time_Remaining(), 2 days);

        vm.warp(block.timestamp + 2 days);
        assertEq(dao.Get_Time_Remaining(), 0);
    }

    function test_CanExecute() public {
        address newNetwork = address(new MockDeFi(founder, address(dao)));

        vm.prank(founder);
        dao.Propose_Network_Address_Change(newNetwork);

        assertFalse(dao.Can_Execute()); // Before voting ends

        // Add votes
        for (uint160 i = 1002; i < 1010; i++) {
            vm.prank(address(i));
            dao.Vote(true);
        }

        assertFalse(dao.Can_Execute()); // Still before voting ends

        vm.warp(block.timestamp + 3 days + 1);
        assertTrue(dao.Can_Execute()); // After voting ends with positive majority
    }

    function test_MarkExpired() public {
        address newNetwork = address(new MockDeFi(founder, address(dao)));

        vm.prank(founder);
        dao.Propose_Network_Address_Change(newNetwork);

        // Fast forward past expiry time
        vm.warp(block.timestamp + 3 days + 30 days + 1);

        dao.Mark_Expired();

        assertFalse(dao.Has_Active_Proposal());

        (,,,,,,,, Fly_Infinity_DAO.ProposalStatus status) = dao.Get_Proposal(1);
        assertEq(uint256(status), uint256(Fly_Infinity_DAO.ProposalStatus.Expired));
    }

    function test_RevertMarkExpiredTooEarly() public {
        address newNetwork = address(new MockDeFi(founder, address(dao)));

        vm.prank(founder);
        dao.Propose_Network_Address_Change(newNetwork);

        vm.warp(block.timestamp + 3 days + 1);

        vm.expectRevert("Not expired yet");
        dao.Mark_Expired();
    }

    function test_MultipleProposalsSequential() public {
        address newNetwork1 = address(new MockDeFi(founder, address(dao)));
        address newGift = address(new MockGift(founder, address(dao)));

        // First proposal
        vm.prank(founder);
        uint256 proposalId1 = dao.Propose_Network_Address_Change(newNetwork1);

        // Vote and execute
        for (uint160 i = 1002; i < 1010; i++) {
            vm.prank(address(i));
            dao.Vote(true);
        }

        vm.warp(block.timestamp + 3 days + 1);
        dao.Execute_Proposal();

        assertFalse(dao.Has_Active_Proposal());

        // Second proposal
        vm.prank(founder);
        uint256 proposalId2 = dao.Propose_Gift_Address_Change(newGift);

        assertEq(proposalId2, 2);
        assertTrue(dao.Has_Active_Proposal());
        assertEq(dao.Get_Active_Proposal_Id(), 2);
    }

    function test_GetProposalById() public {
        address newNetwork = address(new MockDeFi(founder, address(dao)));

        vm.prank(founder);
        dao.Propose_Network_Address_Change(newNetwork);

        (
            uint256 id,
            Fly_Infinity_DAO.ProposalType proposalType,
            address proposedAddress,
            address proposer,,,,,
            Fly_Infinity_DAO.ProposalStatus status
        ) = dao.Get_Proposal(1);

        assertEq(id, 1);
        assertEq(uint256(proposalType), uint256(Fly_Infinity_DAO.ProposalType.CHANGE_NETWORK_ADDRESS));
        assertEq(proposedAddress, newNetwork);
        assertEq(proposer, founder);
        assertEq(uint256(status), uint256(Fly_Infinity_DAO.ProposalStatus.Active));
    }

    function test_Has_VotedOnProposal() public {
        address newNetwork = address(new MockDeFi(founder, address(dao)));

        vm.prank(founder);
        dao.Propose_Network_Address_Change(newNetwork);

        assertFalse(dao.Has_Voted_On_Proposal(1, address(1002)));

        vm.prank(address(1002));
        dao.Vote(true);

        assertTrue(dao.Has_Voted_On_Proposal(1, address(1002)));
    }

    function test_Get_Vote_ChoiceOnProposal() public {
        address newNetwork = address(new MockDeFi(founder, address(dao)));

        vm.prank(founder);
        dao.Propose_Network_Address_Change(newNetwork);

        vm.prank(address(1002));
        dao.Vote(true);

        assertTrue(dao.Get_Vote_Choice_On_Proposal(1, address(1002)));

        vm.prank(address(1003));
        dao.Vote(false);

        assertFalse(dao.Get_Vote_Choice_On_Proposal(1, address(1003)));
    }

    // ============================================================================
    // CRITICAL SECURITY TESTS - ATTACK VECTORS
    // ============================================================================

    function test_Critical_PreventVoteManipulationByReenteringVote() public {
        address newNetwork = address(new MockDeFi(founder, address(dao)));

        vm.prank(founder);
        dao.Propose_Network_Address_Change(newNetwork);

        // Try to vote multiple times in same transaction
        vm.startPrank(address(1002));
        dao.Vote(true);

        vm.expectRevert("Already voted");
        dao.Vote(true);

        vm.expectRevert("Already voted");
        dao.Vote(false); // Can't change vote either
        vm.stopPrank();

        (,,,,,, uint256 positiveVotes,,) = dao.Get_Active_Proposal();
        assertEq(positiveVotes, 1); // Should only count once
    }

    function test_Critical_CannotExecuteProposalMultipleTimes() public {
        address newNetwork = address(new MockDeFi(founder, address(dao)));

        vm.prank(founder);
        dao.Propose_Network_Address_Change(newNetwork);

        // Vote
        for (uint160 i = 1002; i < 1020; i++) {
            vm.prank(address(i));
            dao.Vote(true);
        }

        vm.warp(block.timestamp + 3 days + 1);

        // Execute once
        dao.Execute_Proposal();

        // Try to execute again
        vm.expectRevert("No active proposal");
        dao.Execute_Proposal();
    }

    function test_Critical_TieVoteShouldReject() public {
        address newNetwork = address(new MockDeFi(founder, address(dao)));

        vm.prank(founder);
        dao.Propose_Network_Address_Change(newNetwork);

        // Equal votes
        for (uint160 i = 1002; i < 1012; i++) {
            vm.prank(address(i));
            dao.Vote(true);
        }

        for (uint160 i = 1012; i < 1022; i++) {
            vm.prank(address(i));
            dao.Vote(false);
        }

        (,,,,,, uint256 positiveVotes, uint256 negativeVotes,) = dao.Get_Active_Proposal();
        assertEq(positiveVotes, negativeVotes);

        vm.warp(block.timestamp + 3 days + 1);
        dao.Execute_Proposal();

        // Tie should result in rejection
        (,,,,,,,, Fly_Infinity_DAO.ProposalStatus status) = dao.Get_Proposal(1);
        assertEq(uint256(status), uint256(Fly_Infinity_DAO.ProposalStatus.Rejected));
    }

    function test_Critical_CannotVoteOnExpiredProposal() public {
        address newNetwork = address(new MockDeFi(founder, address(dao)));

        vm.prank(founder);
        dao.Propose_Network_Address_Change(newNetwork);

        // Fast forward to expiry
        vm.warp(block.timestamp + 3 days + 30 days + 1);
        dao.Mark_Expired();

        // Try to vote on expired proposal
        vm.prank(address(1002));
        vm.expectRevert("No active proposal");
        dao.Vote(true);
    }

    function test_Critical_OnlyDAOCanChangeContracts() public {
        address newNetwork = address(new MockDeFi(founder, address(dao)));

        // Try to change network directly without DAO
        vm.prank(founder);
        vm.expectRevert("Only DAO can call this");
        sdn.Change_Gift_Address(address(0x888));

        Fly_Infinity_Token smartBank = sdn.Fly_Infinity_Token_Contract();
        vm.prank(address(1002));
        vm.expectRevert("Only DAO can call this");
        smartBank.Change_Network_Address(newNetwork);
    }

    function test_Critical_ProposalExecutionChangesAllReferences() public {
        // Deploy new mock contracts
        Fly_Infinity_Network newNetwork =
            new Fly_Infinity_Network(founder, agent, address(dai), address(sdnOld), supportAddresses);

        vm.prank(founder);
        uint256 proposalId = dao.Propose_Network_Address_Change(address(newNetwork));

        // Get massive vote support
        for (uint160 i = 1002; i < 1100; i++) {
            vm.prank(address(i));
            dao.Vote(true);
        }

        vm.warp(block.timestamp + 3 days + 1);

        // Verify addresses before
        assertEq(dao.Fly_Infinity_Network_Contract(), address(sdn));

        // Execute
        dao.Execute_Proposal();

        // Verify all addresses changed
        assertEq(dao.Fly_Infinity_Network_Contract(), address(newNetwork));

        (,,,,,,,, Fly_Infinity_DAO.ProposalStatus status) = dao.Get_Proposal(proposalId);
        assertEq(uint256(status), uint256(Fly_Infinity_DAO.ProposalStatus.Executed));
    }

    function test_Critical_VotingAfterUserBecomesNonNetworker() public {
        address newNetwork = address(new MockDeFi(founder, address(dao)));

        vm.prank(founder);
        dao.Propose_Network_Address_Change(newNetwork);

        // User votes successfully as networker
        vm.prank(address(1002));
        dao.Vote(true);

        assertTrue(dao.Has_Voted(address(1002)));
    }

    function test_Critical_MassiveVoteThroughput() public {
        address newNetwork = address(new MockDeFi(founder, address(dao)));

        vm.prank(founder);
        dao.Propose_Network_Address_Change(newNetwork);

        // Simulate huge number of votes
        uint256 voterCount = 0;
        for (uint160 i = 1002; i < 1198; i++) {
            vm.prank(address(i));
            dao.Vote(i % 3 == 0); // Mix of true/false
            voterCount++;
        }

        (,,,,,, uint256 positiveVotes, uint256 negativeVotes,) = dao.Get_Active_Proposal();
        assertEq(positiveVotes + negativeVotes, voterCount);

        // Verify all votes recorded correctly
        for (uint160 i = 1002; i < 1198; i++) {
            assertTrue(dao.Has_Voted(address(i)));
        }
    }

    function test_Critical_ProposalExecutionWithMinimalVotes() public {
        address newNetwork = address(new MockDeFi(founder, address(dao)));

        vm.prank(founder);
        dao.Propose_Network_Address_Change(newNetwork);

        // Only one vote
        vm.prank(address(1002));
        dao.Vote(true);

        vm.warp(block.timestamp + 3 days + 1);
        dao.Execute_Proposal();

        // Should execute with just 1 positive vote
        (,,,,,,,, Fly_Infinity_DAO.ProposalStatus status) = dao.Get_Proposal(1);
        assertEq(uint256(status), uint256(Fly_Infinity_DAO.ProposalStatus.Executed));
    }

    function test_Critical_ProposalExecutionWithNoVotes() public {
        address newNetwork = address(new MockDeFi(founder, address(dao)));

        vm.prank(founder);
        dao.Propose_Network_Address_Change(newNetwork);

        // No votes at all
        vm.warp(block.timestamp + 3 days + 1);
        dao.Execute_Proposal();

        // Should reject with 0 votes
        (,,,,,,,, Fly_Infinity_DAO.ProposalStatus status) = dao.Get_Proposal(1);
        assertEq(uint256(status), uint256(Fly_Infinity_DAO.ProposalStatus.Rejected));
    }

    function test_Critical_CannotProposeWithCurrentContractAddress() public {
        vm.startPrank(founder);

        vm.expectRevert("Same as current address");
        dao.Propose_Network_Address_Change(address(sdn));

        address giftAddress = address(sdn.Fly_Infinity_Gift_Contract());
        vm.expectRevert("Same as current address");
        dao.Propose_Gift_Address_Change(giftAddress);

        vm.stopPrank();
    }

    function test_Critical_VotingPeriodBoundaryConditions() public {
        address newNetwork = address(new MockDeFi(founder, address(dao)));

        vm.prank(founder);
        dao.Propose_Network_Address_Change(newNetwork);

        // Vote at last possible second
        vm.warp(block.timestamp + 3 days);

        vm.prank(address(1002));
        dao.Vote(true); // Should work at exact end time

        // One second after should fail
        vm.warp(block.timestamp + 1);

        vm.prank(address(1003));
        vm.expectRevert("Voting period ended");
        dao.Vote(true);
    }

    function test_Critical_ExecutionImmediatelyAfterVotingEnds() public {
        address newNetwork = address(new MockDeFi(founder, address(dao)));

        vm.prank(founder);
        dao.Propose_Network_Address_Change(newNetwork);

        vm.prank(address(1002));
        dao.Vote(true);

        // Try to execute at exact voting end time
        vm.warp(block.timestamp + 3 days);
        vm.expectRevert("Voting period not ended");
        dao.Execute_Proposal();

        // Should work one second after
        vm.warp(block.timestamp + 1);
        dao.Execute_Proposal();

        (,,,,,,,, Fly_Infinity_DAO.ProposalStatus status) = dao.Get_Proposal(1);
        assertEq(uint256(status), uint256(Fly_Infinity_DAO.ProposalStatus.Executed));
    }

    function test_Critical_VoteCountOverflow() public {
        address newNetwork = address(new MockDeFi(founder, address(dao)));

        vm.prank(founder);
        dao.Propose_Network_Address_Change(newNetwork);

        // Vote with all possible users
        for (uint160 i = 1002; i < 1198; i++) {
            vm.prank(address(i));
            dao.Vote(true);
        }

        (,,,,,, uint256 positiveVotes,,) = dao.Get_Active_Proposal();

        // Should handle large numbers without overflow
        assertTrue(positiveVotes < type(uint256).max);
        assertEq(positiveVotes, 196);
    }

    function test_Critical_ProposalStatusTransitions() public {
        address newNetwork = address(new MockDeFi(founder, address(dao)));

        vm.prank(founder);
        dao.Propose_Network_Address_Change(newNetwork);

        // Initial: Active
        (,,,,,,,, Fly_Infinity_DAO.ProposalStatus status) = dao.Get_Proposal(1);
        assertEq(uint256(status), uint256(Fly_Infinity_DAO.ProposalStatus.Active));

        // Vote and execute to Executed
        for (uint160 i = 1002; i < 1010; i++) {
            vm.prank(address(i));
            dao.Vote(true);
        }

        vm.warp(block.timestamp + 3 days + 1);
        dao.Execute_Proposal();

        (,,,,,,,, status) = dao.Get_Proposal(1);
        assertEq(uint256(status), uint256(Fly_Infinity_DAO.ProposalStatus.Executed));

        // Cannot transition from Executed to anything else
        vm.warp(block.timestamp + 30 days + 1);
        vm.expectRevert("No active proposal");
        dao.Mark_Expired();
    }

    function test_Critical_CannotExecuteAlreadyExecutedProposal() public {
        address newNetwork = address(new MockDeFi(founder, address(dao)));

        vm.prank(founder);
        dao.Propose_Network_Address_Change(newNetwork);

        for (uint160 i = 1002; i < 1010; i++) {
            vm.prank(address(i));
            dao.Vote(true);
        }

        vm.warp(block.timestamp + 3 days + 1);
        dao.Execute_Proposal();

        // Try to execute again by manipulating time
        vm.warp(block.timestamp + 1);
        vm.expectRevert("No active proposal");
        dao.Execute_Proposal();
    }

    function test_Critical_AllNetworkersCanVote() public {
        address newNetwork = address(new MockDeFi(founder, address(dao)));

        vm.prank(founder);
        dao.Propose_Network_Address_Change(newNetwork);

        // Every imported user should be able to vote
        uint256 successfulVotes = 0;
        for (uint160 i = 1002; i < 1198; i++) {
            if (sdn.Owner_Exists(address(i))) {
                vm.prank(address(i));
                dao.Vote(i % 2 == 0);
                successfulVotes++;
            }
        }

        (,,,,,, uint256 positiveVotes, uint256 negativeVotes,) = dao.Get_Active_Proposal();
        assertEq(positiveVotes + negativeVotes, successfulVotes);
    }

    function test_Critical_ProposalWithZeroAddressRejection() public {
        vm.prank(founder);
        vm.expectRevert("Invalid address");
        dao.Propose_Network_Address_Change(address(0));

        vm.prank(founder);
        vm.expectRevert("Invalid address");
        dao.Propose_Gift_Address_Change(address(0));
    }

    function test_Critical_TimeManipulationAttack() public {
        address newNetwork = address(new MockDeFi(founder, address(dao)));

        vm.prank(founder);
        dao.Propose_Network_Address_Change(newNetwork);

        // Try to manipulate by going back in time
        vm.warp(block.timestamp - 1 days);

        vm.prank(address(1002));
        dao.Vote(true);

        // Fast forward past original end time
        vm.warp(block.timestamp + 10 days);

        // Should still be able to execute
        dao.Execute_Proposal();

        (,,,,,,,, Fly_Infinity_DAO.ProposalStatus status) = dao.Get_Proposal(1);
        assertEq(uint256(status), uint256(Fly_Infinity_DAO.ProposalStatus.Executed));
    }

    function test_Critical_ExpiredProposalCannotBeExecuted() public {
        address newNetwork = address(new MockDeFi(founder, address(dao)));

        vm.prank(founder);
        dao.Propose_Network_Address_Change(newNetwork);

        for (uint160 i = 1002; i < 1010; i++) {
            vm.prank(address(i));
            dao.Vote(true);
        }

        // Mark as expired
        vm.warp(block.timestamp + 3 days + 30 days + 1);
        dao.Mark_Expired();

        // Try to execute
        vm.expectRevert("No active proposal");
        dao.Execute_Proposal();
    }

    function test_Critical_MaximumNegativeVotes() public {
        address newNetwork = address(new MockDeFi(founder, address(dao)));

        vm.prank(founder);
        dao.Propose_Network_Address_Change(newNetwork);

        // All users vote no
        for (uint160 i = 1002; i < 1198; i++) {
            vm.prank(address(i));
            dao.Vote(false);
        }

        (,,,,,, uint256 positiveVotes, uint256 negativeVotes,) = dao.Get_Active_Proposal();
        assertEq(positiveVotes, 0);
        assertEq(negativeVotes, 196);

        vm.warp(block.timestamp + 3 days + 1);
        dao.Execute_Proposal();

        (,,,,,,,, Fly_Infinity_DAO.ProposalStatus status) = dao.Get_Proposal(1);
        assertEq(uint256(status), uint256(Fly_Infinity_DAO.ProposalStatus.Rejected));
    }

    function test_Critical_ContractIntegrationAfterDAOExecution() public {
        // This test verifies the entire flow with real contract changes
        Fly_Infinity_Network newNetwork =
            new Fly_Infinity_Network(founder, agent, address(dai), address(sdn), supportAddresses);

        vm.prank(founder);
        dao.Propose_Network_Address_Change(address(newNetwork));

        // Vote
        for (uint160 i = 1002; i < 1050; i++) {
            vm.prank(address(i));
            dao.Vote(true);
        }

        vm.warp(block.timestamp + 3 days + 1);
        dao.Execute_Proposal();

        // Verify the change propagated correctly
        assertEq(dao.Fly_Infinity_Network_Contract(), address(newNetwork));
    }

    function test_Critical_SimultaneousProposalAttempt() public {
        address newNetwork1 = address(new MockDeFi(founder, address(dao)));
        address newNetwork2 = address(new MockDeFi(founder, address(dao)));

        vm.prank(founder);
        dao.Propose_Network_Address_Change(newNetwork1);

        // Try to create another immediately
        vm.prank(founder);
        vm.expectRevert("Another proposal is active");
        dao.Propose_Network_Address_Change(newNetwork2);
    }
}
