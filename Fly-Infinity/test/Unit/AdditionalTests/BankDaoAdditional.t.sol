// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

import {Fly_Infinity_Network, Fly_Infinity_Token} from "../../../src/Fly_Infinity_Network.sol";
import {Smart_DeFi_NetWork} from "../../mocks/oldContractMock.sol";
import {Fly_Infinity_DAO} from "../../../src/Fly_Infinity_DAO.sol";
import {DAI} from "../../mocks/DAI.sol";

/// @notice Additional tests for Bank/DAO edge scenarios:
/// - Bank.Set_DAO_Contract behaviour (race / one-shot semantics)
/// - Bank purchase limit enforcement
contract BankDaoAdditionalTests is Test {
    Fly_Infinity_Network sdn;
    Smart_DeFi_NetWork sdnOld;
    Fly_Infinity_DAO dao;
    Fly_Infinity_Token bank;
    DAI dai;

    address[1] oldAddresses;
    address[1] newAddresses;
    address[4] supportAddresses;

    address founder = address(100);
    address agent = address(101);
    address founderWallet = address(103);
    address smartGift = address(104);
    address daiHolder = address(105);
    address root = address(106);

    address dummyDao1 = address(new DAI(daiHolder, type(uint256).max));
    address dummyDao2 = address(new DAI(daiHolder, type(uint256).max));

    function setUp() public {
        dai = new DAI(daiHolder, type(uint256).max);

        // Old network setup (similar pattern as other tests)
        sdnOld = new Smart_DeFi_NetWork(root, founder, address(dai), address(0xB0A1), founderWallet, smartGift, agent);
        _bootstrapOldNetwork();

        sdn = new Fly_Infinity_Network(founder, agent, address(dai), address(sdnOld), supportAddresses);

        vm.prank(founder);
        sdn.Import_Batch(300);

        bank = sdn.Fly_Infinity_Token_Contract();

        // Give the bank its initial liquidity so price logic works
        vm.startPrank(root);
        dai.transfer(root, 10e18);
        dai.approve(address(bank), 10e18);
        bank.Genesis_Liquidity(10e18);
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

    /// -----------------------------------------------------------------------
    /// Bank.Set_DAO_Contract semantics
    /// -----------------------------------------------------------------------

    function test_Bank_SetDAOContract_OneShotAndRequiresContract() public {

        // Second call should always revert, regardless of sender
        vm.prank(founder);
        vm.expectRevert("DAO already set");
        bank.Set_DAO_Contract(dummyDao2);

        // For completeness, deploy a real DAO and verify it cannot overwrite
        dao = new Fly_Infinity_DAO(founder, address(sdn), address(bank), address(sdn.Fly_Infinity_Gift_Contract()));

        vm.prank(founder);
        vm.expectRevert("DAO already set");
        bank.Set_DAO_Contract(address(dao));
    }

    /// -----------------------------------------------------------------------
    /// Purchase limit enforcement (calculatePurchaseLimit / totalPurchased)
    /// -----------------------------------------------------------------------

    function test_Bank_PurchaseLimit_EnforcedPerUser() public {

        // Prepare a networker
        address user = address(3000);
        vm.prank(daiHolder);
        dai.transfer(user, 500e18);
        vm.prank(user);
        dai.approve(address(bank), 500e18);

        // Ensure user is an owner in the network via registration
        vm.startPrank(user);
        dai.approve(address(sdn), 150e18);
        sdn.Agreement_Road_Map();
        sdn.BeCome_Owner(address(1199));
        vm.stopPrank();

        // Query initial remaining limit
        uint256 initialLimit = bank.Get_Remaining_Purchase_Limit(user);
        assertGt(initialLimit, 0);

        // Perform a buy for half of the limit
        uint256 firstBuy = initialLimit / 2;
        vm.prank(user);
        bank.Buy(user, firstBuy);

        uint256 remainingAfterFirst = bank.Get_Remaining_Purchase_Limit(user);
        assertEq(remainingAfterFirst, initialLimit - firstBuy);

        // Buy up to the rest of the limit
        vm.prank(user);
        bank.Buy(user, remainingAfterFirst);

        uint256 remainingAfterSecond = bank.Get_Remaining_Purchase_Limit(user);
        assertEq(remainingAfterSecond, 0);

        // Any further buy attempt should revert with limit error
        vm.prank(user);
        vm.expectRevert("Purchase exceeds network activity limit");
        bank.Buy(user, 1e18);
    }
}

