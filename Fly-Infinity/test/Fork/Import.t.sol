// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Fly_Infinity_Network} from "./Mock/Smart_DeFi_NetWork.sol";
import {ISmart_DeFi_Network} from "./interfaces/ISmart_DeFi_Network.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ImportMechanismForkTest is Test {
    Fly_Infinity_Network sdn;
    ISmart_DeFi_Network sdnOld;
    IERC20 dai;

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

    // Test: Setting old contract address
    function test_SetOldContract() public view {
        assertEq(sdn.Old_Contract_Address(), address(sdnOld));
    }

    // // Test: New registrations work after import completion
    // function test_NewRegistration_AfterImport() public {
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
    function test_Fork_NewRegistration_BlockedDuringImport() public {
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

    // Test: Import status query
    function test_Fork_ImportStatus_Query() public {
        assertFalse(sdn.Import_Status());
    }

    function test_Fork_Migrate() public view {
        // assertEq(sdn.All_Owner_Number(), sdnOld.All_Owner_Number());

        address[] memory usersOld = sdnOld.All_Owner_Address(0, 100);
        address[] memory usersNew = sdn.All_Owner_Address(0, 100);
        assertEq(usersOld.length, usersNew.length);
        for (uint256 i = 0; i < usersOld.length - 3; i++) {
            // assertEq(_checkFounders(usersOld[i]), usersNew[i]);
            ISmart_DeFi_Network.Node memory oldUser = sdnOld.Owner_Info_Global(usersOld[i]);
            Fly_Infinity_Network.Node memory newUser = sdn.Owner_Info_Global(_checkFounders(usersOld[i]));
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
    }

    function test_Fork_CompareOwnerAllTeamValues() public view {
        // Get all addresses from old contract
        uint64 totalOldUsers = sdn.All_Owner_Number();

        // Check Owner_All_Team for all users
        for (uint32 i = 0; i < totalOldUsers; i++) {
            address[] memory userArr = sdnOld.All_Owner_Address(i, i);
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

    function test_Fork_CompareOwnerLeftRightSaveValues() public view {
        // Get all addresses from old contract
        uint64 totalOldUsers = sdn.All_Owner_Number();

        // Check Owner_Left_Right_Save for all users
        for (uint32 i = 0; i < totalOldUsers; i++) {
            address[] memory userArr = sdnOld.All_Owner_Address(i, i);
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

    function test_Fork_CompareOwnerAllPointValues() public view {
        // Get all addresses from old contract
        uint64 totalOldUsers = sdn.All_Owner_Number();

        // Check Owner_All_Point for all users
        for (uint32 i = 0; i < totalOldUsers; i++) {
            address[] memory userArr = sdnOld.All_Owner_Address(i, i);
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

    function test_Fork_CompareOwnerBigSideValues() public view {
        // Get all addresses from old contract
        uint64 totalOldUsers = sdn.All_Owner_Number();

        // Check Owner_Big_Side for all users
        for (uint32 i = 0; i < totalOldUsers; i++) {
            address[] memory userArr = sdnOld.All_Owner_Address(i, i);
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

    function test_Fork_CompareOwnerDirectsValues() public view {
        // Get all addresses from old contract
        uint64 totalOldUsers = sdn.All_Owner_Number();

        // Check Owner_Directs for all users
        for (uint32 i = 0; i < totalOldUsers; i++) {
            address[] memory userArr = sdnOld.All_Owner_Address(i, i);
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

    function test_Fork_CompareOwnerUpLineValues() public view {
        // Get all addresses from old contract
        uint64 totalOldUsers = sdn.All_Owner_Number();

        // Check Owner_UpLine for all users
        for (uint32 i = 0; i < totalOldUsers; i++) {
            address[] memory userArr = sdnOld.All_Owner_Address(i, i);
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

    function testCompareOwnerLeftRightAllValues() public view {
        // Get all addresses from old contract
        uint64 totalOldUsers = sdn.All_Owner_Number();

        // Check Owner_Left_Right_All for all users
        for (uint32 i = 0; i < totalOldUsers; i++) {
            address[] memory userArr = sdnOld.All_Owner_Address(i, i);
            address userAddr = userArr[0];

            (uint32 oldAL, uint32 oldAR) = sdnOld.Owner_Left_Right_All(userAddr);
            (uint32 newAL, uint32 newAR) = sdn.Owner_Left_Right_All(_checkFounders(userAddr));

            assertEq(newAL, oldAL, string(abi.encodePacked("All_Left mismatch for user at index ", vm.toString(i))));
            assertEq(newAR, oldAR, string(abi.encodePacked("All_Right mismatch for user at index ", vm.toString(i))));
        }
    }
}
