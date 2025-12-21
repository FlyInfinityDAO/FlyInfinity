// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Fly_Infinity_Network} from "../../../src/Fly_Infinity_Network.sol";
import {Smart_DeFi_NetWork} from "../../mocks/oldContractMock.sol";
import {Fly_Infinity_Gift} from "../../../src/Fly_Infinity_Gift.sol";
import {Fly_Infinity_Token} from "../../../src/Fly_Infinity_Token.sol";
import {DAI} from "../../mocks/DAI.sol";

contract NetworkMechanismTest is Test {
    Fly_Infinity_Network sdn;
    Smart_DeFi_NetWork sdnOld;
    Fly_Infinity_Gift giftContract;
    Fly_Infinity_Token bankContract;
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

    // Helper function to find next available parent in binary tree
    function findNextParent(uint256 startId) internal view returns (address) {
        // Start from the given ID and find first address with < 2 directs
        for (uint256 i = startId; i < startId + 1000; i++) {
            address candidate = address(uint160(i));
            if (sdn.Owner_Exists(candidate)) {
                (address left, address right) = sdn.Owner_Directs(candidate);
                // If either position is empty, this can be a parent
                if (left == address(0) || right == address(0)) {
                    return candidate;
                }
            }
        }
        revert("No available parent found");
    }

    // Helper to register users in binary tree pattern
    function registerBinaryTree(uint256 startUserId, uint256 count, uint256 startParentId) internal {
        for (uint256 i = 0; i < count; i++) {
            address newUser = address(uint160(startUserId + i));
            address parent = findNextParent(startParentId);
            register(newUser, parent);
        }
    }

    // ============ REGISTRATION TESTS ============

    function test_RegistrationDAIFlow() public {
        address newUser = address(2000);
        address parent = findNextParent(1002); // Start from imported users

        fundDai(newUser);

        uint256 userBalanceBefore = dai.balanceOf(newUser);
        uint256 networkBalanceBefore = dai.balanceOf(address(sdn));
        uint256 giftBalanceBefore = dai.balanceOf(address(giftContract));
        uint256 bankBalanceBefore = dai.balanceOf(address(bankContract));
        uint256 userTokenBalance = bankContract.balanceOf(newUser);

        vm.startPrank(newUser);
        sdn.Agreement_Road_Map();
        sdn.BeCome_Owner(parent);
        vm.stopPrank();

        // Verify user paid 100 DAI
        assertEq(dai.balanceOf(newUser), userBalanceBefore - 100e18, "User should pay 100 DAI");

        // Verify 5 DAI went to gift contract
        assertEq(dai.balanceOf(address(giftContract)), giftBalanceBefore + 5e18, "Gift should receive 5 DAI");

        // Verify 2 DAI went to bank (through buy function)
        assertEq(dai.balanceOf(address(bankContract)), bankBalanceBefore + 2e18, "Bank should receive 2 DAI");

        // Remaining 93 DAI should be in network contract
        assertEq(dai.balanceOf(address(sdn)), networkBalanceBefore + 93e18, "Network should have 93 DAI (100 - 5 - 2)");

        assertEq(bankContract.balanceOf(newUser), userTokenBalance + 194e16, "User should get new tokens");

        console.log("Registration DAI Flow Test Passed");
        console.log("User paid: 100 DAI");
        console.log("Gift received: 5 DAI");
        console.log("Bank received: 2 DAI");
        console.log("Network retained: 93 DAI");
    }

    function test_RegistrationBankTokenMinting() public {
        address newUser = address(2001);
        address parent = findNextParent(1002);

        fundDai(newUser);

        uint256 userBankBalanceBefore = bankContract.balanceOf(newUser);

        vm.startPrank(newUser);
        sdn.Agreement_Road_Map();
        sdn.BeCome_Owner(parent);
        vm.stopPrank();

        uint256 userBankBalanceAfter = bankContract.balanceOf(newUser);

        // User should receive bank tokens for their 2 DAI purchase
        assertTrue(userBankBalanceAfter > userBankBalanceBefore, "User should receive bank tokens");

        console.log("Bank tokens minted for user:", userBankBalanceAfter);
    }

    function test_MultipleRegistrationsAccumulateDAI() public {
        uint256 networkBalanceBefore = dai.balanceOf(address(sdn));
        uint256 giftBalanceBefore = dai.balanceOf(address(giftContract));
        uint256 bankBalanceBefore = dai.balanceOf(address(bankContract));

        // Register 10 users in binary tree pattern
        registerBinaryTree(3000, 10, 1002);

        // Verify accumulated amounts
        assertEq(dai.balanceOf(address(giftContract)), giftBalanceBefore + (10 * 5e18), "Gift should accumulate 50 DAI");
        assertEq(dai.balanceOf(address(bankContract)), bankBalanceBefore + (10 * 2e18), "Bank should accumulate 20 DAI");
        assertEq(dai.balanceOf(address(sdn)), networkBalanceBefore + (10 * 93e18), "Network should accumulate 930 DAI");

        console.log("Multiple registrations test passed");
        console.log("10 users registered, total accumulated correctly");
    }

    // ============ REWARD FEE TESTS ============

    function test_RewardFeeImpactOnDistribution() public {
        // First set reward fee to 1
        vm.prank(agent);
        sdn._Set_Reward_Fee(1);

        // Register 10 users in binary tree
        registerBinaryTree(4000, 10, 1002);

        uint256 networkBalanceBefore = dai.balanceOf(address(sdn));
        uint256 newOwnerCount = sdn._New_Owner_Status();

        console.log("Network balance before reward:", networkBalanceBefore / 1e18);
        console.log("New owner count:", newOwnerCount);

        // Warp time to allow reward
        vm.warp(block.timestamp + 2 hours);

        uint256 bankBalanceBefore = dai.balanceOf(address(bankContract));

        // Find a user with points to trigger reward
        address rewardWriter = address(1002);

        uint256 rewardWriterBalBefore = dai.balanceOf(rewardWriter);
        vm.prank(rewardWriter);
        sdn.Reward();

        uint256 networkBalanceAfter = dai.balanceOf(address(sdn));
        uint256 bankBalanceAfter = dai.balanceOf(address(bankContract));

        console.log("Network balance after reward:", networkBalanceAfter / 1e18);
        console.log("Bank balance after reward:", (bankBalanceAfter - bankBalanceBefore) / 1e18);

        // With reward fee = 1, reward writer gets (newOwnerCount * 1 * 1e18) / 2
        uint256 expectedWriterReward = (newOwnerCount * 1e18) / 2;
        console.log("Expected writer reward:", expectedWriterReward / 1e18);
        console.log("Actual writer reward:", (dai.balanceOf(rewardWriter) - rewardWriterBalBefore) / 1e18);
    }

    function test_RewardFeeComparison() public {
        uint256[] memory rewardFees = new uint256[](3);
        rewardFees[0] = 1;
        rewardFees[1] = 3;
        rewardFees[2] = 5;

        for (uint256 feeIndex = 0; feeIndex < rewardFees.length; feeIndex++) {
            uint256 currentFee = rewardFees[feeIndex];

            vm.prank(agent);
            sdn._Set_Reward_Fee(currentFee);

            // Register 10 users in binary tree
            registerBinaryTree(5000 + (feeIndex * 100), 10, 1002);

            uint256 networkBalanceBefore = dai.balanceOf(address(sdn));
            uint256 bankBefore = dai.balanceOf(address(bankContract));
            address rewardWriter = address(1002);
            uint256 writerBalanceBefore = dai.balanceOf(rewardWriter);

            // Warp and trigger reward
            vm.warp(2 days + (feeIndex * 2 hours));
            vm.prank(rewardWriter);
            sdn.Reward();

            uint256 writerBalanceAfter = dai.balanceOf(rewardWriter);
            uint256 writerReward = writerBalanceAfter - writerBalanceBefore;

            console.log("\n=== Reward Fee:", currentFee, "===");
            console.log("Network balance before:", networkBalanceBefore / 1e18);
            console.log("Bank Received:", (dai.balanceOf(address(bankContract)) - bankBefore) / 1e18);
            console.log("Writer reward received:", writerReward / 1e18);
            console.log("New owner count:", uint256(10));
            console.log("Last point value:", sdn.Last_Value_Point());
            console.log("Last point Count:", sdn.Last_Total_Point());
            console.log("Expected writer reward:", (10 * currentFee * 1e18) / 2 / 1e18);
        }
    }

    function test_DetailedRewardDistributionFlow() public {
        vm.prank(agent);
        sdn._Set_Reward_Fee(5);

        // Register users in proper binary tree structure
        registerBinaryTree(8001, 5, 1002);

        // Capture balances before reward
        uint256 networkBalanceBefore = dai.balanceOf(address(sdn));
        address rewardWriter = address(1002);
        uint256 writerBalanceBefore = dai.balanceOf(rewardWriter);
        uint256 bankBalanceBefore = dai.balanceOf(address(bankContract));

        uint256 newOwnerCount = sdn._New_Owner_Status();

        console.log("\n=== Detailed Reward Distribution ===");
        console.log("Network balance before:", networkBalanceBefore / 1e18);
        console.log("New owner count:", newOwnerCount);
        console.log("Reward fee:", sdn.Reward_Fee_Status());

        // Warp time
        vm.warp(block.timestamp + 2 hours);

        // Trigger reward
        vm.prank(rewardWriter);
        sdn.Reward();

        // Capture balances after
        uint256 writerBalanceAfter = dai.balanceOf(rewardWriter);
        uint256 bankBalanceAfter = dai.balanceOf(address(bankContract));
        uint256 networkBalanceAfter = dai.balanceOf(address(sdn));

        console.log("\nBalances After Reward:");
        console.log("Reward writer gain:", (writerBalanceAfter - writerBalanceBefore) / 1e18);
        console.log("Bank balance increase:", (bankBalanceAfter - bankBalanceBefore) / 1e18);
        console.log("Network balance after:", networkBalanceAfter / 1e18);

        // Verify writer reward calculation
        uint256 expectedWriterReward = (newOwnerCount * 5 * 1e18) / 2;
        console.log("Expected writer reward:", expectedWriterReward / 1e18);
    }

    function test_RewardPoolWithVaryingRewardFees() public {
        // Test how reward pool changes with different fees
        for (uint256 fee = 1; fee <= 5; fee += 1) {
            vm.prank(agent);
            sdn._Set_Reward_Fee(fee);

            // Register 20 users in binary tree
            registerBinaryTree(6000 + (fee * 100), 20, 1002);

            uint256 networkBalanceBefore = dai.balanceOf(address(sdn));
            uint256 totalPointsBefore = sdn._New_Owner_Status();

            vm.warp(block.timestamp + 2 hours);

            address rewardWriter = address(1002);
            vm.prank(rewardWriter);
            sdn.Reward();

            uint256 networkBalanceAfter = dai.balanceOf(address(sdn));
            uint256 bankBalanceAfter = dai.balanceOf(address(bankContract));

            console.log("\n=== Fee Level:", fee, "===");
            console.log("Network balance before:", networkBalanceBefore / 1e18);
            console.log("Network balance after:", networkBalanceAfter / 1e18);
            console.log("Bank received:", bankBalanceAfter / 1e18);
            console.log("Writer reward portion:", (totalPointsBefore * fee * 1e18 / 2) / 1e18);
        }
    }

    function test_LargeScaleRewardDistribution() public {
        vm.prank(agent);
        sdn._Set_Reward_Fee(5);

        console.log("\n=== Large Scale Reward Distribution Test ===");

        // Build a large network (50 users in binary tree)
        uint256 numUsers = 50;
        registerBinaryTree(7000, numUsers, 1002);

        uint256 networkBalanceBefore = dai.balanceOf(address(sdn));
        uint256 newOwnerCount = sdn._New_Owner_Status();

        console.log("Registered users:", numUsers);
        console.log("New owner count:", newOwnerCount);
        console.log("Network balance:", networkBalanceBefore / 1e18);

        vm.warp(block.timestamp + 2 hours);

        address rewardWriter = address(1002);
        uint256 writerBalanceBefore = dai.balanceOf(rewardWriter);
        vm.prank(rewardWriter);
        sdn.Reward();
        uint256 writerBalanceAfter = dai.balanceOf(rewardWriter);

        uint256 networkBalanceAfter = dai.balanceOf(address(sdn));
        uint256 bankBalanceAfter = dai.balanceOf(address(bankContract));

        console.log("\nPost-Reward State:");
        console.log("Writer reward:", (writerBalanceAfter - writerBalanceBefore) / 1e18);
        console.log("Network balance after:", networkBalanceAfter / 1e18);
        console.log("Bank balance:", bankBalanceAfter / 1e18);
        console.log("Total DAI distributed:", (networkBalanceBefore - networkBalanceAfter) / 1e18);
    }

    function test_RewardDistributionWithMaxPoints() public {
        vm.prank(agent);
        sdn._Set_Reward_Fee(4);

        console.log("\n=== Reward Distribution with Max Points ===");

        // Register 30 users in binary tree
        registerBinaryTree(8000, 30, 1002);

        uint256 rootAllPoints = sdn.Owner_All_Point(address(1002));
        console.log("Parent all points:", rootAllPoints);

        vm.warp(block.timestamp + 2 hours);

        address rewardWriter = address(1002);
        uint256 writerBalanceBefore = dai.balanceOf(rewardWriter);
        vm.prank(rewardWriter);
        sdn.Reward();
        uint256 writerBalanceAfter = dai.balanceOf(rewardWriter);

        console.log("Reward writer reward:", (writerBalanceAfter - writerBalanceBefore) / 1e18);
        console.log("Max point status:", sdn.Owner_Max_Point_Status(address(1002)));
    }

    function test_RewardCounterIncrement() public {
        vm.prank(agent);
        sdn._Set_Reward_Fee(3);

        uint256 rewardCounterBefore = sdn.Reward_Counter_Status();

        // Register users in binary tree
        registerBinaryTree(9000, 10, 1002);

        vm.warp(block.timestamp + 2 hours);

        address rewardWriter = address(1002);
        vm.prank(rewardWriter);
        sdn.Reward();

        uint256 rewardCounterAfter = sdn.Reward_Counter_Status();

        assertEq(rewardCounterAfter, rewardCounterBefore + 1, "Reward counter should increment by 1");
        console.log("Reward counter incremented from", rewardCounterBefore, "to", rewardCounterAfter);
    }

    function test_ValuePointTracking() public {
        vm.prank(agent);
        sdn._Set_Reward_Fee(4);

        registerBinaryTree(10000, 15, 1002);

        vm.warp(block.timestamp + 2 hours);

        address rewardWriter = address(1002);
        vm.prank(rewardWriter);
        sdn.Reward();

        uint256 lastValuePoint = sdn.Last_Value_Point();
        uint32 lastTotalPoint = sdn.Last_Total_Point();

        console.log("\n=== Value Point Tracking ===");
        console.log("Last value point:", lastValuePoint);
        console.log("Last total point:", lastTotalPoint);

        assertTrue(lastValuePoint > 0, "Last value point should be set");
        assertTrue(lastTotalPoint > 0, "Last total point should be set");
    }

    function test_CompleteRewardCycle() public {
        vm.prank(agent);
        sdn._Set_Reward_Fee(3);

        console.log("\n=== Complete Reward Cycle Test ===");

        // Cycle 1: Register and distribute
        registerBinaryTree(11000, 8, 1002);

        uint256 networkBalance1 = dai.balanceOf(address(sdn));
        console.log("Network balance after registrations:", networkBalance1 / 1e18);

        vm.warp(block.timestamp + 2 hours);

        address rewardWriter = address(1002);
        vm.prank(rewardWriter);
        sdn.Reward();

        uint256 networkBalance2 = dai.balanceOf(address(sdn));
        console.log("Network balance after reward 1:", networkBalance2 / 1e18);

        // Cycle 2: Register more and distribute again
        registerBinaryTree(11100, 8, 1002);

        uint256 networkBalance3 = dai.balanceOf(address(sdn));
        console.log("Network balance after more registrations:", networkBalance3 / 1e18);

        vm.warp(block.timestamp + 2 hours);
        vm.prank(rewardWriter);
        sdn.Reward();

        uint256 networkBalance4 = dai.balanceOf(address(sdn));
        console.log("Network balance after reward 2:", networkBalance4 / 1e18);

        // Verify counter incremented twice
        assertEq(sdn.Reward_Counter_Status(), 2, "Should have 2 reward cycles");
    }

    function test_PointBroadcastBeforeReward() public {
        vm.prank(agent);
        sdn._Set_Reward_Fee(5);

        // Register exactly 5 users
        registerBinaryTree(12000, 5, 1002);

        uint256 newOwnerBefore = sdn._New_Owner_Status();
        console.log("New owner count before broadcast:", newOwnerBefore);

        // Manually trigger point broadcast
        address broadcaster = address(1002);
        vm.prank(broadcaster);
        sdn.Point_BroadCast();

        uint256 newOwnerAfter = sdn._New_Owner_Status();
        console.log("New owner count after broadcast:", newOwnerAfter);

        assertEq(newOwnerAfter, 0, "New owner count should reset after broadcast");
    }

    function test_BinaryTreeStructureValidation() public {
        console.log("\n=== Binary Tree Structure Validation ===");

        // Register users and verify tree structure
        address parent1 = findNextParent(1002);
        address newUser1 = address(20000);
        register(newUser1, parent1);

        (address left1, address right1) = sdn.Owner_Directs(parent1);
        console.log("Parent has left:", left1 != address(0));
        console.log("Parent has right:", right1 != address(0));

        // Try to register second child
        address newUser2 = address(20001);
        register(newUser2, parent1);

        (address left2, address right2) = sdn.Owner_Directs(parent1);
        assertTrue(left2 != address(0) && right2 != address(0), "Parent should now have 2 directs");

        // Try to register third child - should find new parent
        address newUser3 = address(20002);
        address parent2 = findNextParent(1002);
        assertTrue(parent2 != parent1, "Should find different parent when first is full");
        register(newUser3, parent2);

        console.log("Binary tree structure validated correctly");
    }

    function test_RewardWithDifferentNetworkDepths() public {
        vm.prank(agent);
        sdn._Set_Reward_Fee(5);

        console.log("\n=== Reward With Different Network Depths ===");

        // Create deeper network structure
        registerBinaryTree(13000, 30, 1002);

        // Check depth and points of various users
        address topUser = address(1002);
        uint32 topUserPoints = sdn.Owner_All_Point(topUser);

        console.log("Top user points:", topUserPoints);

        vm.warp(block.timestamp + 2 hours);

        uint256 writerBalanceBefore = dai.balanceOf(topUser);
        vm.prank(topUser);
        sdn.Reward();
        uint256 writerBalanceAfter = dai.balanceOf(topUser);

        console.log("Reward distributed:", (writerBalanceAfter - writerBalanceBefore) / 1e18);
    }
}
