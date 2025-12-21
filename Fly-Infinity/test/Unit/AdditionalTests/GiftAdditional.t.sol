// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

import {Fly_Infinity_Gift} from "../../../src/Fly_Infinity_Gift.sol";
import {Fly_Infinity_Network} from "../../../src/Fly_Infinity_Network.sol";
import {Smart_DeFi_NetWork} from "../../mocks/oldContractMock.sol";
import {DAI} from "../../mocks/DAI.sol";

/// @notice Additional focused tests for Gift admin/migration flows that were previously untested.
contract GiftAdditionalTests is Test {
    Fly_Infinity_Network sdn;
    Smart_DeFi_NetWork sdnOld;
    Fly_Infinity_Gift gift;
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

    address dummyDAO = address(new DAI(daiHolder, type(uint256).max));

    function setUp() public {
        dai = new DAI(daiHolder, type(uint256).max);
        sdnOld = new Smart_DeFi_NetWork(root, founder, address(dai), bank, founderWallet, smartGift, agent);

        // Minimal old-network bootstrap: register a few users and run Reward once,
        // to mirror the pattern used in other tests and make import viable.
        _bootstrapOldNetwork();

        sdn = new Fly_Infinity_Network(founder, agent, address(dai), address(sdnOld), supportAddresses);

        // Import enough owners so Gift/Network state is non-trivial.
        vm.prank(founder);
        sdn.Import_Batch(200);

        gift = sdn.Fly_Infinity_Gift_Contract();
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

    function _bootstrapOldNetwork() internal {
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

    /// -----------------------------------------------------------------------
    /// Set_DAO_Contract behaviour
    /// -----------------------------------------------------------------------

    function test_Gift_SetDAOContract_OnlyFounderAndOnce() public {

        // Second attempt must revert
        vm.prank(founder);
        vm.expectRevert("DAO already set");
        gift.Set_DAO_Contract(address(this));
    }

    /// -----------------------------------------------------------------------
    /// Change_Network_Address via DAO
    /// -----------------------------------------------------------------------

    function test_Gift_ChangeNetworkAddress_OnlyDAOAndValidations() public {

        // Only DAO can call
        vm.prank(founder);
        vm.expectRevert("Only DAO can call this");
        gift.Change_Network_Address(address(sdn));

        // Zero address revert
        vm.prank(address(sdn.Fly_Infinity_DAO_Contract()));
        vm.expectRevert("Invalid address");
        gift.Change_Network_Address(address(0));

        // Same address revert
        vm.prank(address(sdn.Fly_Infinity_DAO_Contract()));
        vm.expectRevert("Same as current address");
        gift.Change_Network_Address(address(sdn));

        // EOA revert
        vm.prank(address(sdn.Fly_Infinity_DAO_Contract()));
        vm.expectRevert("New network address can not be wallet");
        gift.Change_Network_Address(address(9999));

        // Happy path: change to a fresh Fly_Infinity_Network instance
        Fly_Infinity_Network newNetwork =
            new Fly_Infinity_Network(founder, agent, address(dai), address(sdnOld), supportAddresses);

        vm.prank(address(sdn.Fly_Infinity_DAO_Contract()));
        gift.Change_Network_Address(address(newNetwork));

        assertEq(gift.Fly_Infinity_Network_Contract(), address(newNetwork));
    }

    /// -----------------------------------------------------------------------
    /// Migrate_Funds_To_New_Gift via DAO
    /// -----------------------------------------------------------------------

    function test_Gift_Migrate_Funds_To_New_Gift_MovesAllBalance() public {
        // Fund the gift contract directly with some DAI
        vm.prank(daiHolder);
        dai.transfer(address(gift), 123e18);

        // New gift target
        Fly_Infinity_Gift newGift = new Fly_Infinity_Gift(founder, address(dai), address(sdn)); // network arg unused for this test

        uint256 balBeforeOld = dai.balanceOf(address(gift));
        uint256 balBeforeNew = dai.balanceOf(address(newGift));
        assertEq(balBeforeOld, 123e18);
        assertEq(balBeforeNew, 0);

        // Zero and self-address validation
        vm.prank(address(sdn.Fly_Infinity_DAO_Contract()));
        vm.expectRevert("Invalid address");
        gift.Migrate_Funds_To_New_Gift(address(0));

        vm.prank(address(sdn.Fly_Infinity_DAO_Contract()));
        vm.expectRevert("Same as current address");
        gift.Migrate_Funds_To_New_Gift(address(gift));

        // EOA not allowed
        vm.prank(address(sdn.Fly_Infinity_DAO_Contract()));
        vm.expectRevert("New gift address can not be wallet");
        gift.Migrate_Funds_To_New_Gift(address(7777));

        // Actual migration
        vm.prank(address(sdn.Fly_Infinity_DAO_Contract()));
        gift.Migrate_Funds_To_New_Gift(address(newGift));

        assertEq(dai.balanceOf(address(gift)), 0);
        assertEq(dai.balanceOf(address(newGift)), balBeforeOld);
    }

    /// -----------------------------------------------------------------------
    /// UnLess_Gift (emergency drain) time gating
    /// -----------------------------------------------------------------------

    function test_Gift_UnLessGift_TimeAndFounderOnly() public {
        // Fund Gift contract directly
        vm.prank(daiHolder);
        dai.transfer(address(gift), 50e18);

        // Non-founder cannot call
        vm.prank(address(999));
        vm.expectRevert(" Just Founder ");
        gift.UnLess_Gift();

        // Founder too early -> revert
        vm.prank(founder);
        vm.expectRevert(" UnLess Gift Time Has Not Come ");
        gift.UnLess_Gift();

        // Move time forward enough
        vm.warp(block.timestamp + 10 hours);

        // Track recipient hardcoded in contract
        address recipient = address(sdn);
        uint256 recipientBefore = dai.balanceOf(recipient);

        vm.prank(founder);
        gift.UnLess_Gift();

        assertEq(dai.balanceOf(address(gift)), 0);
        assertEq(dai.balanceOf(recipient), recipientBefore + 50e18);
    }
}

