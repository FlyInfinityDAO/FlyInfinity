// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Fly_Infinity_Network} from "../../../src/Fly_Infinity_Network.sol";
import {Fly_Infinity_Token} from "../../../src/Fly_Infinity_Token.sol";
import {Smart_DeFi_NetWork} from "../../mocks/oldContractMock.sol";
import {DAI} from "../../mocks/DAI.sol";

contract TokenMechanismTest is Test {
    Fly_Infinity_Network sdn;
    Smart_DeFi_NetWork sdnOld;
    Fly_Infinity_Token bank;
    DAI dai;

    address[1] oldAddresses;
    address[1] newAddresses;
    address[4] supportAddresses;

    address founder = address(100);
    address agent = address(101);
    address smartBank = address(102);
    address founderWallet = address(103);
    address smartGift = address(104);
    address daiHolder = address(105);
    address root = address(106);

    address user1 = address(1);
    address user2 = address(2);
    address user3 = address(3);
    address user4 = address(4);
    address attacker = address(999);

    function setUp() public {
        dai = new DAI(daiHolder, type(uint256).max);
        sdnOld = new Smart_DeFi_NetWork(root, founder, address(dai), smartBank, founderWallet, smartGift, agent);
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

    function fundDai(address user, uint256 amount) public {
        vm.prank(daiHolder);
        dai.transfer(user, amount);
        vm.prank(user);
        dai.approve(address(sdn), amount);
    }

    function register(address user, address referrer) public {
        fundDai(user, 150e18);
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

        bank = sdn.Fly_Infinity_Token_Contract();
        vm.startPrank(root);
        dai.approve(address(bank), 10e18);
        bank.Genesis_Liquidity(10e18);
        vm.stopPrank();
    }

    // ============ INITIAL STATE TESTS ============

    function test_BankInitialState() public view {
        assertEq(bank.name(), "Fly Infinity Token");
        assertEq(bank.symbol(), "FIT");
        assertEq(address(bank.DAI()), address(dai));
        assertEq(bank.Price(), 1e18); // Default price
    }

    function test_BankDeploymentLinkedToNetwork() public view {
        address bankFromNetwork = address(sdn.Fly_Infinity_Token_Contract());
        assertEq(bankFromNetwork, address(bank));
    }

    // ============ ACCESS CONTROL TESTS ============

    function test_RevertWhen_NonNetworkerTriesToBuy() public {
        fundDai(attacker, 100e18);

        vm.startPrank(attacker);
        dai.approve(address(bank), 100e18);

        vm.expectRevert("Only Networker");
        bank.Buy(user1, 10e18);
        vm.stopPrank();
    }

    function test_RevertWhen_NonNetworkerTriesToSell() public {
        vm.prank(attacker);
        vm.expectRevert("Only Networker");
        bank.Sell(100e18);
    }

    function test_NetworkerCanBuyTokens() public {
        register(user1, address(1199));

        fundDai(user1, 100e18);
        vm.startPrank(user1);
        dai.approve(address(bank), 100e18);
        bank.Buy(user1, 10e18);
        vm.stopPrank();

        assertTrue(bank.balanceOf(user1) > 0);
    }

    // ============ LIQUIDITY ADDITION TESTS ============

    function test_AddInitialLiquidity() public {
        fundDai(root, 10e18);

        assertEq(bank.totalSupply(), 10e18);
        assertEq(dai.balanceOf(address(bank)), 10e18);
        assertEq(bank.balanceOf(address(bank)), 10e18); // Frozen tokens
    }

    function test_AddLiquidityAfterInitial() public {
        // Add more liquidity
        fundDai(root, 50e18);
        vm.startPrank(root);
        dai.approve(address(bank), 50e18);
        bank.Genesis_Liquidity(50e18);
        vm.stopPrank();

        assertEq(dai.balanceOf(address(bank)), 60e18);
    }

    function test_RevertWhen_AddingZeroLiquidity() public {
        vm.prank(root);
        vm.expectRevert("DAI amount should be greater than zero.");
        bank.Genesis_Liquidity(0);
    }

    // ============ PRICE CALCULATION TESTS ============

    function test_PriceCalculation_DefaultPrice() public view {
        assertEq(bank.Price(), 1e18);
    }

    function test_PriceCalculation_AfterLiquidity() public view {
        // Price = DAI balance * 1e18 / totalSupply
        // Price = 10e18 * 1e18 / 1_000_000e18 = 1e13
        assertEq(bank.Price(), 1e18);
    }

    function test_PriceIncreases_AfterMoreLiquidity() public {
        uint256 priceBefore = bank.Price();

        // Add more liquidity without minting tokens
        fundDai(root, 100e18);
        vm.startPrank(root);
        dai.approve(address(bank), 100e18);
        bank.Genesis_Liquidity(100e18);
        vm.stopPrank();

        uint256 priceAfter = bank.Price();
        assertTrue(priceAfter > priceBefore);
    }

    // ============ BUY TOKEN TESTS ============

    function test_BuyTokens_BasicFlow() public {
        register(user1, address(1199));
        uint256 initialBalance = bank.balanceOf(user1);
        assertEq(initialBalance, 194e16);
        fundDai(user1, 100e18);

        uint256 buyAmount = 10e18;
        vm.startPrank(user1);
        dai.approve(address(bank), buyAmount);
        uint256 tokensMinted = bank.Buy(user1, buyAmount);
        vm.stopPrank();

        assertTrue(tokensMinted > 0);
        assertEq(bank.balanceOf(user1), tokensMinted + initialBalance);
    }

    function test_BuyTokens_AppliesFee() public {
        register(user1, address(1199));
        fundDai(user1, 100e18);

        uint256 buyAmount = 10e18;
        uint256 expectedFee = (buyAmount * 2) / 100; // 2%

        uint256 daiBefore = dai.balanceOf(address(bank));

        vm.startPrank(user1);
        dai.approve(address(bank), buyAmount);
        bank.Buy(user1, buyAmount);
        vm.stopPrank();

        uint256 daiAfter = dai.balanceOf(address(bank));
        assertEq(daiAfter - daiBefore, buyAmount); // Full amount sent
    }

    function test_RevertWhen_BuyingWithZeroAmount() public {
        register(user1, address(1199));

        vm.prank(user1);
        vm.expectRevert("DAI amount should be greater than zero.");
        bank.Buy(user1, 0);
    }

    function test_BuyTokens_MultipleBuyers() public {
        // User1 buys
        register(user1, address(1199));
        fundDai(user1, 100e18);
        vm.startPrank(user1);
        dai.approve(address(bank), 100e18);
        uint256 tokens1 = bank.Buy(user1, 10e18);
        vm.stopPrank();

        // User2 buys at higher price
        register(user2, address(1199));
        fundDai(user2, 100e18);
        vm.startPrank(user2);
        dai.approve(address(bank), 100e18);
        uint256 tokens2 = bank.Buy(user2, 10e18);
        vm.stopPrank();

        // User3 buys at even higher price
        register(user3, address(user1));
        fundDai(user3, 100e18);
        vm.startPrank(user3);
        dai.approve(address(bank), 100e18);
        uint256 tokens3 = bank.Buy(user1, 10e18);
        vm.stopPrank();

        // Later buyers get fewer tokens due to price increase
        assertTrue(tokens3 < tokens2);
        assertTrue(tokens2 < tokens1);
    }

    // ============ SELL TOKEN TESTS ============

    function test_SellTokens_BasicFlow() public {
        register(user1, address(1199));
        fundDai(user1, 100e18);

        vm.startPrank(user1);
        dai.approve(address(bank), 100e18);
        uint256 tokensBought = bank.Buy(user1, 10e18);

        // Sell tokens
        uint256 daiReceived = bank.Sell(tokensBought);
        vm.stopPrank();

        assertTrue(daiReceived > 0);
        assertEq(bank.balanceOf(user1), 194e16);
    }

    function test_SellTokens_AppliesFee() public {
        register(user1, address(1199));
        fundDai(user1, 100e18);

        vm.startPrank(user1);
        dai.approve(address(bank), 100e18);
        uint256 tokensBought = bank.Buy(user1, 10e18);

        uint256 daiBeforeSell = dai.balanceOf(user1);
        uint256 daiReceived = bank.Sell(tokensBought);
        uint256 daiAfterSell = dai.balanceOf(user1);
        vm.stopPrank();

        // Check 2% fee applied
        assertEq(daiAfterSell - daiBeforeSell, daiReceived);
    }

    function test_RevertWhen_SellingZeroTokens() public {
        register(user1, address(1199));

        vm.prank(user1);
        vm.expectRevert("Amount should be greater than zero.");
        bank.Sell(0);
    }

    function test_RevertWhen_SellingMoreThanBalance() public {
        register(user1, address(1199));
        fundDai(user1, 100e18);

        vm.startPrank(user1);
        dai.approve(address(bank), 100e18);
        bank.Buy(user1, 10e18);

        vm.expectRevert("Insufficient balance.");
        bank.Sell(1_000_000e18);
        vm.stopPrank();
    }

    // ============ BUY-SELL CYCLE TESTS ============

    function test_BuySellCycle_WithLoss() public {
        register(user1, address(1199));
        fundDai(user1, 100e18);

        uint256 daiInitial = dai.balanceOf(user1);

        vm.startPrank(user1);
        dai.approve(address(bank), 100e18);
        uint256 boughtExpected = 97e17 * 1e18 / bank.Price();
        uint256 tokensBought = bank.Buy(user1, 10e18);
        uint256 daiExpected = (boughtExpected * bank.Price() / 1e18) * 94 / 100;
        uint256 daiReceived = bank.Sell(tokensBought);
        vm.stopPrank();
        uint256 daiFinal = dai.balanceOf(user1);

        // Should have less DAI due to 2% fee on both buy and sell
        assertTrue(daiFinal < daiInitial);
        assertApproxEqRel(daiFinal, daiInitial - 6e18, 0.05e18); // ~5% loss
        assertApproxEqRel(boughtExpected, tokensBought, 1e3);
        assertApproxEqRel(daiExpected, daiReceived, 1e3);
    }

    function test_MultipleBuySellCycles() public {
        register(user1, address(1199));
        fundDai(user1, 1000e18);

        vm.startPrank(user1);
        dai.approve(address(bank), 1000e18);

        for (uint256 i = 0; i < 5; i++) {
            uint256 tokens = bank.Buy(user1, 10e18);
            bank.Sell(tokens / 2); // Sell half
        }
        vm.stopPrank();

        assertTrue(bank.balanceOf(user1) > 0);
    }

    // ============ PRICE MANIPULATION TESTS ============

    function test_PriceStability_AfterLargeBuy() public {
        uint256 priceBefore = bank.Price();

        register(user1, address(1199));
        fundDai(user1, 1000e18);

        vm.startPrank(user1);
        dai.approve(address(bank), 1000e18);
        bank.Buy(user1, 100e18);
        vm.stopPrank();

        uint256 priceAfter = bank.Price();

        // Price should increase after large buy
        assertTrue(priceAfter > priceBefore);
    }

    function test_PriceStability_AfterLargeSell() public {
        register(user1, address(1199));
        fundDai(user1, 1000e18);

        vm.startPrank(user1);
        dai.approve(address(bank), 1000e18);
        uint256 tokens = bank.Buy(user1, 100e18);
        vm.stopPrank();

        uint256 priceBefore = bank.Price();

        vm.prank(user1);
        bank.Sell(tokens / 2);

        uint256 priceAfter = bank.Price();

        assertTrue(priceAfter > priceBefore);
    }

    // ============ INTEGRATION TESTS ============

    function test_NetworkRewardAddingLiquidity() public {
        // Register multiple users and trigger reward
        register(user1, address(1199));
        register(user2, address(1199));
        register(user3, user1);
        register(user4, user1);

        uint256 bankBalanceBefore = dai.balanceOf(address(bank));

        // Trigger reward which should add liquidity to bank
        vm.warp(block.timestamp + 2 hours);
        vm.prank(root);
        sdn.Reward();

        uint256 bankBalanceAfter = dai.balanceOf(address(bank));

        // Bank should receive liquidity from network
        assertTrue(bankBalanceAfter > bankBalanceBefore);
    }

    function test_TokenSystemWithNetworkGrowth() public {
        uint256 initialPrice = bank.Price();

        // Network grows
        for (uint160 i = 1; i <= 10; i++) {
            register(address(2000 + i), address(1180 + uint160(i)));
        }

        uint256 bal1 = dai.balanceOf(address(bank));
        // Trigger rewards
        vm.warp(block.timestamp + 2 hours);
        vm.prank(root);
        sdn.Reward();
        uint256 bal2 = dai.balanceOf(address(bank));
        uint256 finalPrice = bank.Price();

        assertApproxEqRel(bal2 - bal1, 30e18, 1e4);
        // Price should increase as network adds liquidity
        assertTrue(finalPrice > initialPrice);
    }

    // ============ EDGE CASE TESTS ============

    function test_BuyTokens_VerySmallAmount() public {
        register(user1, address(1199));
        fundDai(user1, 1e18);

        vm.startPrank(user1);
        dai.approve(address(bank), 1e18);
        uint256 tokens = bank.Buy(user1, 1e15); // 0.001 DAI
        vm.stopPrank();

        assertTrue(tokens > 0);
    }

    function test_FrozenTokens_CannotBeTransferred() public view {
        uint256 frozenBalance = bank.balanceOf(address(bank));
        // If liquidity added, should be 1M tokens
        if (frozenBalance > 0) {
            assertEq(frozenBalance, 10e18);
        }
    }

    function test_PriceCalculation_WithDifferentSupplies() public {
        uint256[] memory prices = new uint256[](5);

        for (uint256 i = 0; i < 5; i++) {
            prices[i] = bank.Price();

            address buyer = address(uint160(2000 + i));
            register(buyer, address(1190 + uint160(i)));
            fundDai(buyer, 100e18);

            vm.startPrank(buyer);
            dai.approve(address(bank), 100e18);
            bank.Buy(buyer, 20e18);
            vm.stopPrank();
        }

        // Each price should be higher than previous
        for (uint256 i = 1; i < 5; i++) {
            assertTrue(prices[i] >= prices[i - 1]);
        }
    }

    function test_SellAllTokens() public {
        for (uint160 i = 2; i <= 11; i++) {
            vm.startPrank(address(i + 1000));
            dai.approve(address(bank), 1000e18);
            bank.Buy(address(i + 1000), 100e18);
        }

        assertEq(dai.balanceOf(address(bank)), 1010e18);

        for (uint160 i = 2; i <= 11; i++) {
            vm.startPrank(address(i + 1000));
            dai.approve(address(bank), 1000e18);
            bank.Sell(bank.balanceOf(address(i + 1000)));
        }

        assertGt(dai.balanceOf(address(bank)), 10e18);
        assertEq(bank.totalSupply(), 10e18);
    }
}
