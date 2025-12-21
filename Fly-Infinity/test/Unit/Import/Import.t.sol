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
        fundDaiOld(user);
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

    // Test: Import small batch
    function test_ImportBatch_SmallBatch() public {
        sdn = new Fly_Infinity_Network(founder, agent, address(dai), address(sdnOld), supportAddresses);

        vm.startPrank(founder);
        sdn.Import_Batch(5);
        vm.stopPrank();

        assertEq(sdn.All_Owner_Number(), 5);
        assertFalse(sdn.Import_Status());
    }

    // Test: Import multiple batches
    function test_ImportBatch_MultipleBatches() public {
        sdn = new Fly_Infinity_Network(founder, agent, address(dai), address(sdnOld), supportAddresses);

        vm.startPrank(founder);
        sdn.Import_Batch(50);
        assertEq(sdn.All_Owner_Number(), 50);
        assertFalse(sdn.Import_Status());

        sdn.Import_Batch(50);
        assertEq(sdn.All_Owner_Number(), 100);
        assertFalse(sdn.Import_Status());

        sdn.Import_Batch(100);
        assertEq(sdn.All_Owner_Number(), 199);
        assertTrue(sdn.Import_Status());
        vm.stopPrank();
    }

    // Test: Import handles completion correctly
    function test_ImportBatch_CompletesAtEnd() public {
        sdn = new Fly_Infinity_Network(founder, agent, address(dai), address(sdnOld), supportAddresses);

        vm.startPrank(founder);
        sdn.Import_Batch(300); // More than total users
        vm.stopPrank();

        assertTrue(sdn.Import_Status());
        assertEq(sdn.All_Owner_Number(), sdnOld.All_Owner_Number());
    }

    // Test: Cannot import after completion
    function test_ImportBatch_CannotImportAfterCompletion() public {
        sdn = new Fly_Infinity_Network(founder, agent, address(dai), address(sdnOld), supportAddresses);

        vm.startPrank(founder);
        sdn.Import_Batch(300);

        vm.expectRevert("Import already completed");
        sdn.Import_Batch(10);
        vm.stopPrank();
    }

    // Test: Imported data integrity
    function test_ImportBatch_DataIntegrity() public {
        sdn = new Fly_Infinity_Network(founder, agent, address(dai), address(sdnOld), supportAddresses);

        vm.startPrank(founder);
        sdn.Import_Batch(200);
        vm.stopPrank();

        // Check random users
        address testUser1 = address(1002);
        address testUser2 = address(1050);

        Smart_DeFi_NetWork.Node memory oldNode1 = sdnOld.Owner_Info_Global(testUser1);
        Fly_Infinity_Network.Node memory newNode1 = sdn.Owner_Info_Global(testUser1);
        Smart_DeFi_NetWork.Node memory oldNode2 = sdnOld.Owner_Info_Global(testUser2);
        Fly_Infinity_Network.Node memory newNode2 = sdn.Owner_Info_Global(testUser2);

        assertEq(oldNode1.AL, newNode1.AL);
        assertEq(oldNode1.AR, newNode1.AR);
        assertEq(oldNode1.LT, newNode1.LT);
        assertEq(oldNode1.RT, newNode1.RT);
        assertEq(oldNode1.UP, newNode1.UP);
        assertEq(oldNode1.PO, newNode1.PO);
        assertEq(oldNode1.QO, newNode1.QO);
        assertEq(oldNode1.XI, newNode1.XI);
        assertEq(oldNode1.YY, newNode1.YY);

        assertEq(oldNode2.AL, newNode2.AL);
        assertEq(oldNode2.AR, newNode2.AR);
        assertEq(oldNode2.LT, newNode2.LT);
        assertEq(oldNode2.RT, newNode2.RT);
        assertEq(oldNode2.UP, newNode2.UP);
        assertEq(oldNode2.PO, newNode2.PO);
        assertEq(oldNode2.QO, newNode2.QO);
        assertEq(oldNode2.XI, newNode2.XI);
        assertEq(oldNode2.YY, newNode2.YY);
    }

    // Test: Max point status is preserved
    function test_ImportBatch_MaxPointPreserved() public {
        // Setup max point in old contract for a user
        address testUser = address(1002);
        Smart_DeFi_NetWork.Node memory oldNode = sdnOld.Owner_Info_Global(testUser);

        sdn = new Fly_Infinity_Network(founder, agent, address(dai), address(sdnOld), supportAddresses);

        vm.startPrank(founder);
        sdn.Import_Batch(10);
        vm.stopPrank();

        bool oldMaxPoint = sdnOld.Owner_Max_Point_Status(testUser);
        bool newMaxPoint = sdn.Owner_Max_Point_Status(testUser);
        assertEq(oldMaxPoint, newMaxPoint);
    }

    // Test: All addresses are correctly mapped
    function test_ImportBatch_AddressMapping() public {
        sdn = new Fly_Infinity_Network(founder, agent, address(dai), address(sdnOld), supportAddresses);

        vm.startPrank(founder);
        sdn.Import_Batch(200);
        vm.stopPrank();

        address[] memory _newAddresses = sdnOld.All_Owner_Address(0, 50);
        address[] memory _oldAddresses = sdn.All_Owner_Address(0, 50);

        for (uint256 i = 0; i < oldAddresses.length; i++) {
            assertEq(_newAddresses[i], _oldAddresses[i]);
        }
    }

    // Test: New registrations work after import completion
    function test_NewRegistration_AfterImport() public {
        sdn = new Fly_Infinity_Network(founder, agent, address(dai), address(sdnOld), supportAddresses);

        vm.startPrank(founder);
        sdn.Import_Batch(200);
        vm.stopPrank();

        address newUser = address(9999);
        vm.prank(daiHolder);
        dai.transfer(newUser, 150e18);

        vm.startPrank(newUser);
        dai.approve(address(sdn), 150e18);
        sdn.Agreement_Road_Map();
        sdn.BeCome_Owner(address(1199));
        vm.stopPrank();

        assertTrue(sdn.Owner_Info_Global(newUser).id != 0);
    }

    // Test: Cannot register before import completion
    function test_NewRegistration_BlockedDuringImport() public {
        sdn = new Fly_Infinity_Network(founder, agent, address(dai), address(sdnOld), supportAddresses);

        vm.startPrank(founder);
        sdn.Import_Batch(50); // Partial import
        vm.stopPrank();

        address newUser = address(9999);
        vm.prank(daiHolder);
        dai.transfer(newUser, 150e18);

        vm.startPrank(newUser);
        dai.approve(address(sdn), 150e18);
        sdn.Agreement_Road_Map();
        vm.expectRevert("Import not completed yet");
        sdn.BeCome_Owner(address(1002));
        vm.stopPrank();
    }

    // Test: Waiting flag prevents concurrent imports
    function test_ImportBatch_WaitingFlag() public {
        sdn = new Fly_Infinity_Network(founder, agent, address(dai), address(sdnOld), supportAddresses);

        vm.startPrank(founder);
        // Note: The Waiting flag is set during execution and released at the end
        // This is more of an integration concern, but we can verify it doesn't block sequential calls
        sdn.Import_Batch(10);
        sdn.Import_Batch(10); // Should work if Waiting is properly released
        vm.stopPrank();

        assertEq(sdn.All_Owner_Number(), 20);
    }

    // Test: Import status query
    function test_ImportStatus_Query() public {
        sdn = new Fly_Infinity_Network(founder, agent, address(dai), address(sdnOld), supportAddresses);

        assertFalse(sdn.Import_Status());

        vm.startPrank(founder);
        assertFalse(sdn.Import_Status());

        sdn.Import_Batch(50);
        assertFalse(sdn.Import_Status());

        sdn.Import_Batch(200);
        assertTrue(sdn.Import_Status());
        vm.stopPrank();
    }

    // Test: Excluded address is skipped during import
    function test_ImportBatch_SkipsExcludedAddress() public {
        sdn = new Fly_Infinity_Network(founder, agent, address(dai), address(sdnOld), supportAddresses);

        vm.startPrank(founder);
        sdn.Import_Batch(300);
        vm.stopPrank();

        // Verify excluded address is not imported
        address excluded = 0x76d12C7AfA6c15B310Ce9eA8bDA1bc81Dfe31489;
        Fly_Infinity_Network.Node memory node = sdn.Owner_Info_Global(excluded);
        assertEq(node.id, 0); // Should not exist
    }

    // Test: ID counter increments correctly
    function test_ImportBatch_IDCounter() public {
        sdn = new Fly_Infinity_Network(founder, agent, address(dai), address(sdnOld), supportAddresses);

        vm.startPrank(founder);
        uint64 afterFounder = sdn.All_Owner_Number();

        sdn.Import_Batch(10);
        uint64 afterBatch = sdn.All_Owner_Number();
        vm.stopPrank();

        assertEq(afterFounder, 0);
        assertEq(afterBatch, 10);
    }

    // Test: Complete migration maintains network structure
    function test_CompleteMigration_NetworkStructure() public {
        sdn = new Fly_Infinity_Network(founder, agent, address(dai), address(sdnOld), supportAddresses);

        vm.startPrank(founder);
        sdn.Import_Batch(200);
        vm.stopPrank();

        // Verify upline/downline relationships
        address child = address(1002);
        Fly_Infinity_Network.Node memory childNode = sdn.Owner_Info_Global(child);
        assertEq(childNode.UP, root);

        Fly_Infinity_Network.Node memory parentNode = sdn.Owner_Info_Global(root);
        assertTrue(parentNode.PO == child || parentNode.QO == child);
    }

    // Test: Import maintains team counts
    function test_ImportBatch_TeamCounts() public {
        sdn = new Fly_Infinity_Network(founder, agent, address(dai), address(sdnOld), supportAddresses);

        vm.startPrank(founder);
        sdn.Import_Batch(200);
        vm.stopPrank();

        Smart_DeFi_NetWork.Node memory oldRoot = sdnOld.Owner_Info_Global(root);
        Fly_Infinity_Network.Node memory newRoot = sdn.Owner_Info_Global(root);

        assertEq(oldRoot.AL, newRoot.AL);
        assertEq(oldRoot.AR, newRoot.AR);
        assertEq(oldRoot.LT, newRoot.LT);
        assertEq(oldRoot.RT, newRoot.RT);
    }

    function test_migrationNotStarted() public {
        sdn = new Fly_Infinity_Network(founder, agent, address(dai), address(sdnOld), supportAddresses);
        vm.startPrank(founder);
        sdn.Import_Batch(100);
        vm.stopPrank();

        fundDai(user1);
        vm.startPrank(user1);
        sdn.Agreement_Road_Map();
        vm.expectRevert("Import not completed yet");
        sdn.BeCome_Owner(address(1199));
        vm.stopPrank();

        vm.prank(founder);
        sdn.Import_Batch(100);

        vm.startPrank(user1);
        sdn.BeCome_Owner(address(1199));
        vm.stopPrank();
    }

    function test_migrate() public {
        sdn = new Fly_Infinity_Network(founder, agent, address(dai), address(sdnOld), supportAddresses);
        vm.startPrank(founder);
        sdn.Import_Batch(200);
        vm.stopPrank();
        assertEq(sdn.All_Owner_Number(), sdnOld.All_Owner_Number());

        address[] memory usersOld = sdnOld.All_Owner_Address(0, 200);
        address[] memory usersNew = sdn.All_Owner_Address(0, 200);
        assertEq(usersOld.length, usersNew.length);
        for (uint256 i = 0; i < usersOld.length; i++) {
            assertEq(usersOld[i], usersNew[i]);
            Smart_DeFi_NetWork.Node memory oldUser = sdnOld.Owner_Info_Global(usersOld[i]);
            Smart_DeFi_NetWork.Node memory newUser = sdnOld.Owner_Info_Global(usersNew[i]);
            assertEq(oldUser.AL, newUser.AL);
            assertEq(oldUser.AR, newUser.AR);
            assertEq(oldUser.id, newUser.id);
            assertEq(oldUser.LT, newUser.LT);
            assertEq(oldUser.PO, newUser.PO);
            assertEq(oldUser.QO, newUser.QO);
            assertEq(oldUser.RT, newUser.RT);
            assertEq(oldUser.UP, newUser.UP);
            assertEq(oldUser.XI, newUser.XI);
            assertEq(oldUser.YY, newUser.YY);
            assertEq(sdnOld.Owner_Max_Point_Status(usersNew[i]), sdn.Owner_Max_Point_Status(usersNew[i]));
        }
    }

    function testCompareOwnerAllTeamValues() public {
        sdn = new Fly_Infinity_Network(founder, agent, address(dai), address(sdnOld), supportAddresses);

        vm.startPrank(founder);
        sdn.Import_Batch(200);
        vm.stopPrank();

        // Get all addresses from old contract
        uint64 totalOldUsers = sdnOld.All_Owner_Number();

        // Check Owner_All_Team for all users
        for (uint32 i = 0; i < totalOldUsers; i++) {
            address[] memory userArr = sdnOld.All_Owner_Address(i, i);
            address userAddr = userArr[0];

            if (userAddr == address(0)) continue;

            Smart_DeFi_NetWork.Node memory oldNode = sdnOld.Owner_Info_Global(userAddr);
            if (oldNode.id == 0) continue;

            uint32 oldAllTeam = sdnOld.Owner_All_Team(userAddr);
            uint32 newAllTeam = sdn.Owner_All_Team(userAddr);

            assertEq(
                newAllTeam,
                oldAllTeam,
                string(abi.encodePacked("Owner_All_Team mismatch for user at index ", vm.toString(i)))
            );
        }
    }

    function testCompareOwnerLeftRightSaveValues() public {
        sdn = new Fly_Infinity_Network(founder, agent, address(dai), address(sdnOld), supportAddresses);

        vm.startPrank(founder);
        sdn.Import_Batch(200);
        vm.stopPrank();

        // Get all addresses from old contract
        uint64 totalOldUsers = sdnOld.All_Owner_Number();

        // Check Owner_Left_Right_Save for all users
        for (uint32 i = 0; i < totalOldUsers; i++) {
            address[] memory userArr = sdnOld.All_Owner_Address(i, i);
            address userAddr = userArr[0];

            if (userAddr == address(0)) continue;

            Smart_DeFi_NetWork.Node memory oldNode = sdnOld.Owner_Info_Global(userAddr);
            if (oldNode.id == 0) continue;

            (uint32 oldLeft, uint32 oldRight) = sdnOld.Owner_Left_Right_Save(userAddr);
            (uint32 newLeft, uint32 newRight) = sdn.Owner_Left_Right_Save(userAddr);

            assertEq(
                newLeft, oldLeft, string(abi.encodePacked("Left_Save mismatch for user at index ", vm.toString(i)))
            );
            assertEq(
                newRight, oldRight, string(abi.encodePacked("Right_Save mismatch for user at index ", vm.toString(i)))
            );
        }
    }

    function testCompareOwnerAllPointValues() public {
        sdn = new Fly_Infinity_Network(founder, agent, address(dai), address(sdnOld), supportAddresses);

        vm.startPrank(founder);
        sdn.Import_Batch(200);
        vm.stopPrank();

        // Get all addresses from old contract
        uint64 totalOldUsers = sdnOld.All_Owner_Number();

        // Check Owner_All_Point for all users
        for (uint32 i = 0; i < totalOldUsers; i++) {
            address[] memory userArr = sdnOld.All_Owner_Address(i, i);
            address userAddr = userArr[0];

            if (userAddr == address(0)) continue;

            Smart_DeFi_NetWork.Node memory oldNode = sdnOld.Owner_Info_Global(userAddr);
            if (oldNode.id == 0) continue;

            uint32 oldAllPoint = sdnOld.Owner_All_Point(userAddr);
            uint32 newAllPoint = sdn.Owner_All_Point(userAddr);

            assertEq(
                newAllPoint,
                oldAllPoint,
                string(abi.encodePacked("Owner_All_Point mismatch for user at index ", vm.toString(i)))
            );
        }
    }

    function testCompareOwnerBigSideValues() public {
        sdn = new Fly_Infinity_Network(founder, agent, address(dai), address(sdnOld), supportAddresses);

        vm.startPrank(founder);
        sdn.Import_Batch(200);
        vm.stopPrank();

        // Get all addresses from old contract
        uint64 totalOldUsers = sdnOld.All_Owner_Number();

        // Check Owner_Big_Side for all users
        for (uint32 i = 0; i < totalOldUsers; i++) {
            address[] memory userArr = sdnOld.All_Owner_Address(i, i);
            address userAddr = userArr[0];

            if (userAddr == address(0)) continue;

            Smart_DeFi_NetWork.Node memory oldNode = sdnOld.Owner_Info_Global(userAddr);
            if (oldNode.id == 0) continue;

            uint32 oldBigSide = sdnOld.Owner_Big_Side(userAddr);
            uint32 newBigSide = sdn.Owner_Big_Side(userAddr);

            assertEq(
                newBigSide,
                oldBigSide,
                string(abi.encodePacked("Owner_Big_Side mismatch for user at index ", vm.toString(i)))
            );
        }
    }

    function testCompareOwnerDirectsValues() public {
        sdn = new Fly_Infinity_Network(founder, agent, address(dai), address(sdnOld), supportAddresses);

        vm.startPrank(founder);
        sdn.Import_Batch(200);
        vm.stopPrank();

        // Get all addresses from old contract
        uint64 totalOldUsers = sdnOld.All_Owner_Number();

        // Check Owner_Directs for all users
        for (uint32 i = 0; i < totalOldUsers; i++) {
            address[] memory userArr = sdn.All_Owner_Address(i, i);
            address userAddr = userArr[0];

            if (userAddr == address(0)) continue;

            Smart_DeFi_NetWork.Node memory oldNode = sdnOld.Owner_Info_Global(userAddr);
            if (oldNode.id == 0) continue;

            (address oldLeft, address oldRight) = sdnOld.Owner_Directs(userAddr);
            (address newLeft, address newRight) = sdn.Owner_Directs(userAddr);

            assertEq(
                newLeft, oldLeft, string(abi.encodePacked("Left_Direct mismatch for user at index ", vm.toString(i)))
            );
            assertEq(
                newRight, oldRight, string(abi.encodePacked("Right_Direct mismatch for user at index ", vm.toString(i)))
            );
        }
    }

    function testCompareOwnerUpLineValues() public {
        sdn = new Fly_Infinity_Network(founder, agent, address(dai), address(sdnOld), supportAddresses);

        vm.startPrank(founder);
        sdn.Import_Batch(200);
        vm.stopPrank();

        // Get all addresses from old contract
        uint64 totalOldUsers = sdnOld.All_Owner_Number();

        // Check Owner_UpLine for all users
        for (uint32 i = 0; i < totalOldUsers; i++) {
            address[] memory userArr = sdnOld.All_Owner_Address(i, i);
            address userAddr = userArr[0];

            if (userAddr == address(0)) continue;

            Smart_DeFi_NetWork.Node memory oldNode = sdnOld.Owner_Info_Global(userAddr);
            if (oldNode.id == 0) continue;

            address oldUpLine = sdnOld.Owner_UpLine(userAddr);
            address newUpLine = sdn.Owner_UpLine(userAddr);

            assertEq(
                newUpLine, oldUpLine, string(abi.encodePacked("UpLine mismatch for user at index ", vm.toString(i)))
            );
        }
    }

    function testCompareOwnerLeftRightAllValues() public {
        sdn = new Fly_Infinity_Network(founder, agent, address(dai), address(sdnOld), supportAddresses);

        vm.startPrank(founder);
        sdn.Import_Batch(200);
        vm.stopPrank();

        // Get all addresses from old contract
        uint64 totalOldUsers = sdnOld.All_Owner_Number();

        // Check Owner_Left_Right_All for all users
        for (uint32 i = 0; i < totalOldUsers; i++) {
            address[] memory userArr = sdnOld.All_Owner_Address(i, i);
            address userAddr = userArr[0];

            if (userAddr == address(0)) continue;

            Smart_DeFi_NetWork.Node memory oldNode = sdnOld.Owner_Info_Global(userAddr);
            if (oldNode.id == 0) continue;

            (uint32 oldAL, uint32 oldAR) = sdnOld.Owner_Left_Right_All(userAddr);
            (uint32 newAL, uint32 newAR) = sdn.Owner_Left_Right_All(userAddr);

            assertEq(newAL, oldAL, string(abi.encodePacked("All_Left mismatch for user at index ", vm.toString(i))));
            assertEq(newAR, oldAR, string(abi.encodePacked("All_Right mismatch for user at index ", vm.toString(i))));
        }
    }
}
