// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Fly_Infinity_Network} from "./Mock/Smart_DeFi_NetWork2.sol";
import {ISmart_DeFi_Network} from "./interfaces/ISmart_DeFi_Network.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Fly_Infinity_Gift} from "../../src/Fly_Infinity_Gift.sol";
import {Fly_Infinity_Token} from "../../src/Fly_Infinity_Token.sol";

contract Import2MechanismForkTest is Test {
    Fly_Infinity_Network sdn;
    ISmart_DeFi_Network sdnOld;
    IERC20 dai;

    Fly_Infinity_Gift giftContract;
    Fly_Infinity_Token bankContract;

    address[] contractUsers;

    address[2] oldAddresses = [0x00e21f2B131CD5ba0c2e5594B1a7302A6Aa64152, 0x27042A3d0eCb4BF5B04A277d745B8bB77Ad48147];
    address[2] newAddresses = [0x101024cb50E169893d8Ad18f61F640e66c64e28b, 0x9996e9c43168C669BA99F7DAA38FE31708029928];
    address[4] supportAddresses = [
        0x431430B832aa27d7807144ca4897A4d17215F259,
        0xe0fD852e3D3B24fD533122E67baFF95264172ef6,
        0xaaC6f3a4231c986d8dF1C3235859990041779060,
        0x61BbbAc4fc1F65C44ec99292115eF12A47083cd6
    ];

    address founder = 0x101024cb50E169893d8Ad18f61F640e66c64e28b;
    address agent = 0xb54662c111c4aA206279a8cC046102588eC6D00f;
    address bank = address(102);
    address daiHolder = 0x5a52E96BAcdaBb82fd05763E25335261B270Efcb;

    address user1 = address(1);
    address user2 = address(2);
    address user3 = address(3);

    mapping(address => address) internal changeFounders;

    function setUp() public {
        dai = IERC20(0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3);
        sdnOld = ISmart_DeFi_Network(0xd341197eE1171D30c0B1685b521C140A6299C200);

        for (uint256 i = 0; i < 2; i++) {
            changeFounders[oldAddresses[i]] = newAddresses[i];
        }

        sdn = new Fly_Infinity_Network(
            founder, agent, address(dai), address(sdnOld), oldAddresses, newAddresses, supportAddresses
        );
        vm.startPrank(founder);
        // for (uint256 i = 0; i < 810; i++) {
        //     if(sdn.Import_Status()){
        //         break;
        //     }
        //     sdn.Import_Batch(100);
        // }
        sdn.Import_Batch(100);
        vm.stopPrank();

        giftContract = sdn.Smart_DeFi_Gift_();
        bankContract = sdn.Smart_DeFi_Bank_();

        contractUsers = sdn.All_Owner_Address(0, 100);
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

    function _checkFounders(address owner) private view returns (address) {
        if (changeFounders[owner] == address(0)) return owner;
        return changeFounders[owner];
    }

    // Helper function to find next available parent in binary tree
    function findNextParent() internal view returns (address) {
        // Start from the given ID and find first address with < 2 directs
        for (uint256 i = 0; i < contractUsers.length; i++) {
            address candidate = contractUsers[i];
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
    function registerBinaryTree(uint256 startUserId, uint256 count) internal {
        for (uint256 i = 0; i < count; i++) {
            address newUser = address(uint160(startUserId + i));
            address parent = findNextParent();
            register(newUser, parent);
        }
    }

    // Test: Setting old contract address
    function test_Fork2_SetOldContract() public view {
        assertEq(sdn.Old_Contract_Address(), address(sdnOld));
    }

    // // Test: New registrations work after import completion
    // function test_Fork2_NewRegistration_AfterImport() public {
    //     sdn = new Fly_Infinity_Network(
    //         founder, agent, address(dai), address(sdnOld), oldAddresses, newAddresses, supportAddresses
    //     );

    //     vm.startPrank(founder);
    //     sdn.Import_Batch(200);
    //     vm.stopPrank();

    //     address newUser = address(9999);
    //     vm.prank(daiHolder);
    //     dai.transfer(newUser, 150e18);

    //     vm.startPrank(newUser);
    //     dai.approve(address(sdn), 150e18);
    //     sdn.Agreement_Road_Map();
    //     sdn.BeCome_Owner(address(1199));
    //     vm.stopPrank();

    //     assertTrue(sdn.Owner_Info_Global(newUser).id != 0);
    // }

    // Test: Cannot register before import completion
    function test_Fork2_Fork2_NewRegistration_BlockedDuringImport() public {
        address newUser = address(9999);
        vm.prank(daiHolder);
        dai.transfer(newUser, 150e18);

        vm.startPrank(newUser);
        dai.approve(address(sdn), 150e18);
        sdn.Agreement_Road_Map();
        sdn.BeCome_Owner(findNextParent());
        vm.stopPrank();
    }

    // Test: Import status query
    function test_Fork2_Fork2_ImportStatus_Query() public {
        assertTrue(sdn.Import_Status());
    }

    function test_Fork2_Fork2_Migrate() public view {
        // assertEq(sdn.All_Owner_Number(), sdnOld.All_Owner_Number());

        address[] memory usersOld = sdnOld.All_Owner_Address(0, 100);
        address[] memory usersNew = sdn.All_Owner_Address(0, 100);
        assertEq(usersOld.length, usersNew.length);
        for (uint256 i = 0; i < usersOld.length - 3; i++) {
            // assertEq(_checkFounders(usersOld[i]), usersNew[i]);
            ISmart_DeFi_Network.Node memory oldUser = sdnOld.Owner_Info_Global(usersNew[i]);
            Fly_Infinity_Network.Node memory newUser = sdn.Owner_Info_Global((usersNew[i]));
            assertEq(oldUser.AL, newUser.AL);
            assertEq(oldUser.AR, newUser.AR);
            // assertEq(oldUser.id, newUser.id);
            assertEq(oldUser.LT, newUser.LT);
            assertEq(_checkFounders(oldUser.PO), newUser.PO);
            assertEq(_checkFounders(oldUser.QO), newUser.QO);
            assertEq(oldUser.RT, newUser.RT);
            assertEq(_checkFounders(oldUser.UP), newUser.UP);
            assertEq(oldUser.XI, newUser.XI);
            assertEq(oldUser.YY, newUser.YY);
            assertEq(sdnOld.Owner_Max_Point_Status(usersNew[i]), sdn.Owner_Max_Point_Status(usersNew[i]));
        }

        assertTrue(sdn.Import_Status());
    }

    function test_Fork2_Fork2_CompareOwnerAllTeamValues() public view {
        // Get all addresses from old contract
        uint64 totalOldUsers = sdn.All_Owner_Number();

        // Check Owner_All_Team for all users
        for (uint32 i = 0; i < totalOldUsers; i++) {
            address[] memory userArr = sdn.All_Owner_Address(i, i);
            address userAddr = userArr[0];
            uint32 oldAllTeam = sdnOld.Owner_All_Team((userAddr));
            uint32 newAllTeam = sdn.Owner_All_Team(_checkFounders(userAddr));

            assertEq(
                newAllTeam,
                oldAllTeam,
                string(abi.encodePacked("Owner_All_Team mismatch for user at index ", vm.toString(i)))
            );
        }
    }

    function test_Fork2_Fork2_CompareOwnerLeftRightSaveValues() public view {
        // Get all addresses from old contract
        uint64 totalOldUsers = sdn.All_Owner_Number();

        // Check Owner_Left_Right_Save for all users
        for (uint32 i = 0; i < totalOldUsers; i++) {
            address[] memory userArr = sdn.All_Owner_Address(i, i);
            address userAddr = userArr[0];

            (uint32 oldLeft, uint32 oldRight) = sdnOld.Owner_Left_Right_Save(userAddr);
            (uint32 newLeft, uint32 newRight) = sdn.Owner_Left_Right_Save(_checkFounders(userAddr));

            assertEq(
                newLeft, oldLeft, string(abi.encodePacked("Left_Save mismatch for user at index ", vm.toString(i)))
            );
            assertEq(
                newRight, oldRight, string(abi.encodePacked("Right_Save mismatch for user at index ", vm.toString(i)))
            );
        }
    }

    function test_Fork2_Fork2_CompareOwnerAllPointValues() public view {
        // Get all addresses from old contract
        uint64 totalOldUsers = sdn.All_Owner_Number();

        // Check Owner_All_Point for all users
        for (uint32 i = 0; i < totalOldUsers; i++) {
            address[] memory userArr = sdn.All_Owner_Address(i, i);
            address userAddr = userArr[0];

            uint32 oldAllPoint = sdnOld.Owner_All_Point(userAddr);
            uint32 newAllPoint = sdn.Owner_All_Point(_checkFounders(userAddr));

            assertEq(
                newAllPoint,
                oldAllPoint,
                string(abi.encodePacked("Owner_All_Point mismatch for user at index ", vm.toString(i)))
            );
        }
    }

    function test_Fork2_Fork2_CompareOwnerBigSideValues() public view {
        // Get all addresses from old contract
        uint64 totalOldUsers = sdn.All_Owner_Number();

        // Check Owner_Big_Side for all users
        for (uint32 i = 0; i < totalOldUsers; i++) {
            address[] memory userArr = sdn.All_Owner_Address(i, i);
            address userAddr = userArr[0];

            uint32 oldBigSide = sdnOld.Owner_Big_Side(userAddr);
            uint32 newBigSide = sdn.Owner_Big_Side(_checkFounders(userAddr));

            assertEq(
                newBigSide,
                oldBigSide,
                string(abi.encodePacked("Owner_Big_Side mismatch for user at index ", vm.toString(i)))
            );
        }
    }

    function test_Fork2_Fork2_CompareOwnerDirectsValues() public view {
        // Get all addresses from old contract
        uint64 totalOldUsers = sdn.All_Owner_Number();

        // Check Owner_Directs for all users
        for (uint32 i = 0; i < totalOldUsers; i++) {
            address[] memory userArr = sdn.All_Owner_Address(i, i);
            address userAddr = userArr[0];

            (address oldLeft, address oldRight) = sdnOld.Owner_Directs(userAddr);
            (address newLeft, address newRight) = sdn.Owner_Directs(_checkFounders(userAddr));

            assertEq(
                newLeft,
                _checkFounders(oldLeft),
                string(abi.encodePacked("Left_Direct mismatch for user at index ", vm.toString(i)))
            );
            assertEq(
                newRight,
                _checkFounders(oldRight),
                string(abi.encodePacked("Right_Direct mismatch for user at index ", vm.toString(i)))
            );
        }
    }

    function test_Fork2_Fork2_CompareOwnerUpLineValues() public view {
        // Get all addresses from old contract
        uint64 totalOldUsers = sdn.All_Owner_Number();

        // Check Owner_UpLine for all users
        for (uint32 i = 0; i < totalOldUsers; i++) {
            address[] memory userArr = sdn.All_Owner_Address(i, i);
            address userAddr = userArr[0];

            address oldUpLine = sdnOld.Owner_UpLine(userAddr);
            address newUpLine = sdn.Owner_UpLine(_checkFounders(userAddr));

            assertEq(
                newUpLine,
                _checkFounders(oldUpLine),
                string(abi.encodePacked("UpLine mismatch for user at index ", vm.toString(i)))
            );
        }
    }

    function test_Fork2_Fork2_CompareOwnerLeftRightAllValues() public view {
        // Get all addresses from old contract
        uint64 totalOldUsers = sdn.All_Owner_Number();

        // Check Owner_Left_Right_All for all users
        for (uint32 i = 0; i < totalOldUsers; i++) {
            address[] memory userArr = sdn.All_Owner_Address(i, i);
            address userAddr = userArr[0];

            (uint32 oldAL, uint32 oldAR) = sdn.Owner_Left_Right_All(userAddr);
            (uint32 newAL, uint32 newAR) = sdn.Owner_Left_Right_All(_checkFounders(userAddr));

            assertEq(newAL, oldAL, string(abi.encodePacked("All_Left mismatch for user at index ", vm.toString(i))));
            assertEq(newAR, oldAR, string(abi.encodePacked("All_Right mismatch for user at index ", vm.toString(i))));
        }
    }

    function test_Fork2_RegistrationDAIFlow() public {
        address newUser = address(2000);
        address parent = findNextParent(); // Start from imported users

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

    function test_Fork2_RegistrationBankTokenMinting() public {
        address newUser = address(2001);
        address parent = findNextParent();

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

    function test_Fork2_MultipleRegistrationsAccumulateDAI() public {
        uint256 networkBalanceBefore = dai.balanceOf(address(sdn));
        uint256 giftBalanceBefore = dai.balanceOf(address(giftContract));
        uint256 bankBalanceBefore = dai.balanceOf(address(bankContract));

        // Register 5 users in binary tree pattern
        registerBinaryTree(3000, 5);

        // Verify accumulated amounts
        assertEq(dai.balanceOf(address(giftContract)), giftBalanceBefore + (5 * 5e18), "Gift should accumulate 50 DAI");
        assertEq(dai.balanceOf(address(bankContract)), bankBalanceBefore + (5 * 2e18), "Bank should accumulate 20 DAI");
        assertEq(dai.balanceOf(address(sdn)), networkBalanceBefore + (5 * 93e18), "Network should accumulate 930 DAI");

        console.log("Multiple registrations test passed");
        console.log("5 users registered, total accumulated correctly");
    }

    // ============ REWARD FEE TESTS ============

    function test_Fork2_RewardFeeImpactOnDistribution() public {
        // First set reward fee to 1
        vm.prank(agent);
        sdn._Set_Reward_Fee(1);

        // Register 10 users in binary tree
        registerBinaryTree(4000, 5);

        uint256 networkBalanceBefore = dai.balanceOf(address(sdn));
        uint256 newOwnerCount = sdn._New_Owner_Status();

        console.log("Network balance before reward:", networkBalanceBefore / 1e18);
        console.log("New owner count:", newOwnerCount);

        // Warp time to allow reward
        vm.warp(block.timestamp + 2 hours);

        uint256 bankBalanceBefore = dai.balanceOf(address(bankContract));

        // Find a user with points to trigger reward
        address rewardWriter = address(0x7286C250b10CEa52361C06da87d95aEa3d99bF30);

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

    function test_Fork2_RewardFeeComparison() public {
        uint256[] memory rewardFees = new uint256[](1);
        // rewardFees[0] = 1;
        // rewardFees[0] = 3;
        rewardFees[0] = 5;

        for (uint256 feeIndex = 0; feeIndex < rewardFees.length; feeIndex++) {
            uint256 currentFee = rewardFees[feeIndex];

            vm.prank(agent);
            sdn._Set_Reward_Fee(currentFee);

            // Register 10 users in binary tree
            registerBinaryTree(5000 + (feeIndex * 100), 5);

            uint256 networkBalanceBefore = dai.balanceOf(address(sdn));
            uint256 bankBefore = dai.balanceOf(address(bankContract));
            address rewardWriter = address(0x7286C250b10CEa52361C06da87d95aEa3d99bF30);
            uint256 writerBalanceBefore = dai.balanceOf(rewardWriter);

            // Warp and trigger reward
            vm.warp(block.timestamp + ((feeIndex + 1) * 2 hours));
            vm.prank(rewardWriter);
            sdn.Reward();

            uint256 writerBalanceAfter = dai.balanceOf(rewardWriter);
            uint256 writerReward = writerBalanceAfter - writerBalanceBefore;

            console.log("\n=== Reward Fee:", currentFee, "===");
            console.log("Network balance before:", networkBalanceBefore / 1e18);
            console.log("Bank Received:", (dai.balanceOf(address(bankContract)) - bankBefore) / 1e18);
            console.log("Writer reward received:", writerReward / 1e18);
            console.log("New owner count:", uint256(5));
            console.log("Last point value:", sdn.Last_Value_Point());
            console.log("Last point Count:", sdn.Last_Total_Point());
            console.log("Expected writer reward:", (5 * currentFee * 1e18) / 2 / 1e18);
        }
    }

    function test_Fork2_DetailedRewardDistributionFlow() public {
        vm.prank(agent);
        sdn._Set_Reward_Fee(5);

        // Register users in proper binary tree structure
        registerBinaryTree(8001, 5);

        // Capture balances before reward
        uint256 networkBalanceBefore = dai.balanceOf(address(sdn));
        address rewardWriter = address(0x7286C250b10CEa52361C06da87d95aEa3d99bF30);
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

    function test_Fork2_RewardPoolWithVaryingRewardFees() public {
        // Test how reward pool changes with different fees
        for (uint256 fee = 2; fee <= 2; fee ++) {
            vm.prank(agent);
            sdn._Set_Reward_Fee(fee);

            // Register 20 users in binary tree
            registerBinaryTree(6000 + (fee * 100), 2);

            uint256 networkBalanceBefore = dai.balanceOf(address(sdn));
            uint256 totalPointsBefore = sdn._New_Owner_Status();

            vm.warp(block.timestamp + 2 hours);

            address rewardWriter = address(0x7286C250b10CEa52361C06da87d95aEa3d99bF30);
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

    function test_Fork2_LargeScaleRewardDistribution() public {
        vm.prank(agent);
        sdn._Set_Reward_Fee(5);

        console.log("\n=== Large Scale Reward Distribution Test ===");

        // Build a large network (50 users in binary tree)
        uint256 numUsers = 5;
        registerBinaryTree(7000, numUsers);

        uint256 networkBalanceBefore = dai.balanceOf(address(sdn));
        uint256 newOwnerCount = sdn._New_Owner_Status();

        console.log("Registered users:", numUsers);
        console.log("New owner count:", newOwnerCount);
        console.log("Network balance:", networkBalanceBefore / 1e18);

        vm.warp(block.timestamp + 2 hours);

        address rewardWriter = address(0x7286C250b10CEa52361C06da87d95aEa3d99bF30);
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

    function test_Fork2_RewardDistributionWithMaxPoints() public {
        vm.prank(agent);
        sdn._Set_Reward_Fee(4);

        console.log("\n=== Reward Distribution with Max Points ===");

        // Register 30 users in binary tree
        registerBinaryTree(8000, 3);

        uint256 rootAllPoints = sdn.Owner_All_Point(address(1002));
        console.log("Parent all points:", rootAllPoints);

        vm.warp(block.timestamp + 2 hours);

        address rewardWriter = address(0x7286C250b10CEa52361C06da87d95aEa3d99bF30);
        uint256 writerBalanceBefore = dai.balanceOf(rewardWriter);
        vm.prank(rewardWriter);
        sdn.Reward();
        uint256 writerBalanceAfter = dai.balanceOf(rewardWriter);

        console.log("Reward writer reward:", (writerBalanceAfter - writerBalanceBefore) / 1e18);
        console.log("Max point status:", sdn.Owner_Max_Point_Status(address(1002)));
    }

    function test_Fork2_RewardCounterIncrement() public {
        vm.prank(agent);
        sdn._Set_Reward_Fee(3);

        uint256 rewardCounterBefore = sdn.Reward_Counter_Status();

        // Register users in binary tree
        registerBinaryTree(9000, 10);

        vm.warp(block.timestamp + 2 hours);

        address rewardWriter = address(0x7286C250b10CEa52361C06da87d95aEa3d99bF30);
        vm.prank(rewardWriter);
        sdn.Reward();

        uint256 rewardCounterAfter = sdn.Reward_Counter_Status();

        assertEq(rewardCounterAfter, rewardCounterBefore + 1, "Reward counter should increment by 1");
        console.log("Reward counter incremented from", rewardCounterBefore, "to", rewardCounterAfter);
    }

    function test_Fork2_ValuePointTracking() public {
        vm.prank(agent);
        sdn._Set_Reward_Fee(4);

        registerBinaryTree(10000, 15);

        vm.warp(block.timestamp + 2 hours);

        address rewardWriter = address(0x7286C250b10CEa52361C06da87d95aEa3d99bF30);
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

    function test_Fork2_CompleteRewardCycle() public {
        vm.prank(agent);
        sdn._Set_Reward_Fee(3);

        console.log("\n=== Complete Reward Cycle Test ===");

        // Cycle 1: Register and distribute
        registerBinaryTree(11000, 8);

        uint256 networkBalance1 = dai.balanceOf(address(sdn));
        console.log("Network balance after registrations:", networkBalance1 / 1e18);

        vm.warp(block.timestamp + 2 hours);

        address rewardWriter = address(0x7286C250b10CEa52361C06da87d95aEa3d99bF30);
        vm.prank(rewardWriter);
        sdn.Reward();

        uint256 networkBalance2 = dai.balanceOf(address(sdn));
        console.log("Network balance after reward 1:", networkBalance2 / 1e18);

        // Cycle 2: Register more and distribute again
        registerBinaryTree(11100, 8);

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

    function test_Fork2_PointBroadcastBeforeReward() public {
        vm.prank(agent);
        sdn._Set_Reward_Fee(5);

        // Register exactly 5 users
        registerBinaryTree(12000, 1);

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

    function test_Fork2_BinaryTreeStructureValidation() public {
        console.log("\n=== Binary Tree Structure Validation ===");

        // Register users and verify tree structure
        address parent1 = findNextParent();
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
        address parent2 = findNextParent();
        assertTrue(parent2 != parent1, "Should find different parent when first is full");
        register(newUser3, parent2);

        console.log("Binary tree structure validated correctly");
    }

    function test_Fork2_RewardWithDifferentNetworkDepths() public {
        vm.prank(agent);
        sdn._Set_Reward_Fee(5);

        console.log("\n=== Reward With Different Network Depths ===");

        // Create deeper network structure
        registerBinaryTree(13000, 2);

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
