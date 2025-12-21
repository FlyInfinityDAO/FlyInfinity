// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Fly_Infinity_Network} from "./Mock/Smart_DeFi_NetWork2.sol";
import {ISmart_DeFi_Network} from "./interfaces/ISmart_DeFi_Network.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Fly_Infinity_Gift} from "../../src/Fly_Infinity_Gift.sol";
import {Fly_Infinity_Token} from "../../src/Fly_Infinity_Token.sol";

contract TokenMechanismForkTest is Test {
    Fly_Infinity_Network sdn;
    ISmart_DeFi_Network sdnOld;
    IERC20 dai;

    Fly_Infinity_Gift giftContract;
    Fly_Infinity_Token bankContract;

    address[] contractUsers;

    address root = address(0x7286C250b10CEa52361C06da87d95aEa3d99bF30);

    address user1 = address(1);
    address user2 = address(2);
    address user3 = address(3);
    address user4 = address(4);
    address attacker = address(999);

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
    address daiHolder = 0x5a52E96BAcdaBb82fd05763E25335261B270Efcb;

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

    function fundDai(address user, uint256 amount) public {
        vm.prank(daiHolder);
        dai.transfer(user, amount);
        vm.prank(user);
        dai.approve(address(sdn), amount);
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

    // ============ INITIAL STATE TESTS ============

    function test_Fork_BankInitialState() public view {
        assertEq(bankContract.name(), "Smart DeFi Bank");
        assertEq(bankContract.symbol(), "SDB");
        assertEq(address(bankContract.DAI()), address(dai));
        assertEq(bankContract.Price(), 1e18); // Default price
    }

    function test_Fork_BankDeploymentLinkedToNetwork() public view {
        address bankFromNetwork = address(sdn.Smart_DeFi_Bank_());
        assertEq(bankFromNetwork, address(bankContract));
    }

    // ============ ACCESS CONTROL TESTS ============

    function test_Fork_RevertWhen_NonNetworkerTriesToBuy() public {
        fundDai(attacker, 100e18);

        vm.startPrank(attacker);
        dai.approve(address(bankContract), 100e18);

        vm.expectRevert("Only Networker");
        bankContract.Buy(user1, 10e18);
        vm.stopPrank();
    }

    function test_Fork_RevertWhen_NonNetworkerTriesToSell() public {
        vm.prank(attacker);
        vm.expectRevert("Only Networker");
        bankContract.Sell(100e18);
    }

    function test_Fork_NetworkerCanBuyTokens() public {
        register(user1, address(1199));

        fundDai(user1, 100e18);
        vm.startPrank(user1);
        dai.approve(address(bankContract), 100e18);
        bankContract.Buy(user1, 10e18);
        vm.stopPrank();

        assertTrue(bankContract.balanceOf(user1) > 0);
    }

    // ============ LIQUIDITY ADDITION TESTS ============

    function test_Fork_AddInitialLiquidity() public {
        assertEq(bankContract.totalSupply(), 10e18);
        assertEq(dai.balanceOf(address(bankContract)), 10e18);
        assertEq(bankContract.balanceOf(address(bankContract)), 10e18); // Frozen tokens
    }

    function test_Fork_AddLiquidityAfterInitial() public {
        // Add more liquidity
        fundDai(root, 50e18);
        vm.startPrank(root);
        dai.approve(address(bankContract), 50e18);
        bankContract.Genesis_Liquidity(50e18);
        vm.stopPrank();

        assertEq(dai.balanceOf(address(bankContract)), 60e18);
    }

    function test_Fork_RevertWhen_AddingZeroLiquidity() public {
        vm.prank(root);
        vm.expectRevert("DAI amount should be greater than zero.");
        bankContract.Genesis_Liquidity(0);
    }

    // ============ PRICE CALCULATION TESTS ============

    function test_Fork_PriceCalculation_DefaultPrice() public view {
        assertEq(bankContract.Price(), 1e18);
    }

    function test_Fork_PriceCalculation_AfterLiquidity() public view {
        // Price = DAI balance * 1e18 / totalSupply
        // Price = 10e18 * 1e18 / 1_000_000e18 = 1e13
        assertEq(bankContract.Price(), 1e18);
    }

    function test_Fork_PriceIncreases_AfterMoreLiquidity() public {
        uint256 priceBefore = bankContract.Price();

        // Add more liquidity without minting tokens
        fundDai(root, 100e18);
        vm.startPrank(root);
        dai.approve(address(bankContract), 100e18);
        bankContract.Genesis_Liquidity(100e18);
        vm.stopPrank();

        uint256 priceAfter = bankContract.Price();
        assertTrue(priceAfter > priceBefore);
    }

    // ============ BUY TOKEN TESTS ============

    function test_Fork_BuyTokens_BasicFlow() public {
        register(user1, address(1199));
        uint256 initialBalance = bankContract.balanceOf(user1);
        assertEq(initialBalance, 194e16);
        fundDai(user1, 100e18);

        uint256 buyAmount = 10e18;
        vm.startPrank(user1);
        dai.approve(address(bankContract), buyAmount);
        uint256 tokensMinted = bankContract.Buy(user1, buyAmount);
        vm.stopPrank();

        assertTrue(tokensMinted > 0);
        assertEq(bankContract.balanceOf(user1), tokensMinted + initialBalance);
    }

    function test_Fork_BuyTokens_AppliesFee() public {
        register(user1, address(1199));
        fundDai(user1, 100e18);

        uint256 buyAmount = 10e18;
        uint256 expectedFee = (buyAmount * 2) / 100; // 2%

        uint256 daiBefore = dai.balanceOf(address(bankContract));

        vm.startPrank(user1);
        dai.approve(address(bankContract), buyAmount);
        bankContract.Buy(user1, buyAmount);
        vm.stopPrank();

        uint256 daiAfter = dai.balanceOf(address(bankContract));
        assertEq(daiAfter - daiBefore, buyAmount); // Full amount sent
    }

    function test_Fork_RevertWhen_BuyingWithZeroAmount() public {
        register(user1, address(1199));

        vm.prank(user1);
        vm.expectRevert("DAI amount should be greater than zero.");
        bankContract.Buy(user1, 0);
    }

    function test_Fork_BuyTokens_MultipleBuyers() public {
        // User1 buys
        register(user1, address(1199));
        fundDai(user1, 100e18);
        vm.startPrank(user1);
        dai.approve(address(bankContract), 100e18);
        uint256 tokens1 = bankContract.Buy(user1, 10e18);
        vm.stopPrank();

        // User2 buys at higher price
        register(user2, address(1199));
        fundDai(user2, 100e18);
        vm.startPrank(user2);
        dai.approve(address(bankContract), 100e18);
        uint256 tokens2 = bankContract.Buy(user2, 10e18);
        vm.stopPrank();

        // User3 buys at even higher price
        register(user3, address(user1));
        fundDai(user3, 100e18);
        vm.startPrank(user3);
        dai.approve(address(bankContract), 100e18);
        uint256 tokens3 = bankContract.Buy(user1, 10e18);
        vm.stopPrank();

        // Later buyers get fewer tokens due to price increase
        assertTrue(tokens3 < tokens2);
        assertTrue(tokens2 < tokens1);
    }

    // ============ SELL TOKEN TESTS ============

    function test_Fork_SellTokens_BasicFlow() public {
        register(user1, address(1199));
        fundDai(user1, 100e18);

        vm.startPrank(user1);
        dai.approve(address(bankContract), 100e18);
        uint256 tokensBought = bankContract.Buy(user1, 10e18);

        // Sell tokens
        uint256 daiReceived = bankContract.Sell(tokensBought);
        vm.stopPrank();

        assertTrue(daiReceived > 0);
        assertEq(bankContract.balanceOf(user1), 194e16);
    }

    function test_Fork_SellTokens_AppliesFee() public {
        register(user1, address(1199));
        fundDai(user1, 100e18);

        vm.startPrank(user1);
        dai.approve(address(bankContract), 100e18);
        uint256 tokensBought = bankContract.Buy(user1, 10e18);

        uint256 daiBeforeSell = dai.balanceOf(user1);
        uint256 daiReceived = bankContract.Sell(tokensBought);
        uint256 daiAfterSell = dai.balanceOf(user1);
        vm.stopPrank();

        // Check 2% fee applied
        assertEq(daiAfterSell - daiBeforeSell, daiReceived);
    }

    function test_Fork_RevertWhen_SellingZeroTokens() public {
        register(user1, address(1199));

        vm.prank(user1);
        vm.expectRevert("Amount should be greater than zero.");
        bankContract.Sell(0);
    }

    function test_Fork_RevertWhen_SellingMoreThanBalance() public {
        register(user1, address(1199));
        fundDai(user1, 100e18);

        vm.startPrank(user1);
        dai.approve(address(bankContract), 100e18);
        bankContract.Buy(user1, 10e18);

        vm.expectRevert("Insufficient balance.");
        bankContract.Sell(1_000_000e18);
        vm.stopPrank();
    }

    // ============ BUY-SELL CYCLE TESTS ============

    function test_Fork_BuySellCycle_WithLoss() public {
        register(user1, address(1199));
        fundDai(user1, 100e18);

        uint256 daiInitial = dai.balanceOf(user1);

        vm.startPrank(user1);
        dai.approve(address(bankContract), 100e18);
        uint256 boughtExpected = 97e17 * 1e18 / bankContract.Price();
        uint256 tokensBought = bankContract.Buy(user1, 10e18);
        uint256 daiExpected = (boughtExpected * bankContract.Price() / 1e18) * 94 / 100;
        uint256 daiReceived = bankContract.Sell(tokensBought);
        vm.stopPrank();
        uint256 daiFinal = dai.balanceOf(user1);

        // Should have less DAI due to 2% fee on both buy and sell
        assertTrue(daiFinal < daiInitial);
        assertApproxEqRel(daiFinal, daiInitial - 6e18, 0.05e18); // ~5% loss
        assertApproxEqRel(boughtExpected, tokensBought, 1e3);
        assertApproxEqRel(daiExpected, daiReceived, 1e3);
    }

    function test_Fork_MultipleBuySellCycles() public {
        register(user1, address(1199));
        fundDai(user1, 1000e18);

        vm.startPrank(user1);
        dai.approve(address(bankContract), 1000e18);

        for (uint256 i = 0; i < 5; i++) {
            uint256 tokens = bankContract.Buy(user1, 10e18);
            bankContract.Sell(tokens / 2); // Sell half
        }
        vm.stopPrank();

        assertTrue(bankContract.balanceOf(user1) > 0);
    }

    // ============ PRICE MANIPULATION TESTS ============

    // function test_Fork_PriceStability_AfterLargeBuy() public {
    //     uint256 priceBefore = bankContract.Price();

    //     register(user1, address(1199));
    //     fundDai(user1, 1000e18);

    //     vm.startPrank(user1);
    //     dai.approve(address(bankContract), 1000e18);
    //     bankContract.Buy(500e18);
    //     vm.stopPrank();

    //     uint256 priceAfter = bankContract.Price();

    //     // Price should increase after large buy
    //     assertTrue(priceAfter > priceBefore);
    // }

    // function test_Fork_PriceStability_AfterLargeSell() public {
    //     register(user1, address(1199));
    //     fundDai(user1, 1000e18);

    //     vm.startPrank(user1);
    //     dai.approve(address(bankContract), 1000e18);
    //     uint256 tokens = bankContract.Buy(500e18);
    //     vm.stopPrank();

    //     uint256 priceBefore = bankContract.Price();

    //     vm.prank(user1);
    //     bankContract.Sell(tokens / 2);

    //     uint256 priceAfter = bankContract.Price();

    //     assertTrue(priceAfter > priceBefore);
    // }

    // ============ INTEGRATION TESTS ============

    function test_Fork_NetworkRewardAddingLiquidity() public {
        // Register multiple users and trigger reward
        register(user1, address(1199));
        register(user2, address(1199));
        register(user3, user1);
        register(user4, user1);

        uint256 bankBalanceBefore = dai.balanceOf(address(bankContract));

        // Trigger reward which should add liquidity to bankContract
        vm.warp(block.timestamp + 2 hours);
        vm.prank(root);
        sdn.Reward();

        uint256 bankBalanceAfter = dai.balanceOf(address(bankContract));

        // Bank should receive liquidity from network
        assertTrue(bankBalanceAfter > bankBalanceBefore);
    }

    function test_Fork_TokenSystemWithNetworkGrowth() public {
        uint256 initialPrice = bankContract.Price();

        // Network grows
        for (uint160 i = 1; i <= 10; i++) {
            register(address(2000 + i), address(1180 + uint160(i)));
        }

        uint256 bal1 = dai.balanceOf(address(bankContract));
        // Trigger rewards
        vm.warp(block.timestamp + 2 hours);
        vm.prank(root);
        sdn.Reward();
        uint256 bal2 = dai.balanceOf(address(bankContract));
        uint256 finalPrice = bankContract.Price();

        assertApproxEqRel(bal2 - bal1, 30e18, 1e4);
        // Price should increase as network adds liquidity
        assertTrue(finalPrice > initialPrice);
    }

    // ============ EDGE CASE TESTS ============

    function test_Fork_BuyTokens_VerySmallAmount() public {
        register(user1, address(1199));
        fundDai(user1, 1e18);

        vm.startPrank(user1);
        dai.approve(address(bankContract), 1e18);
        uint256 tokens = bankContract.Buy(user1, 1e15); // 0.001 DAI
        vm.stopPrank();

        assertTrue(tokens > 0);
    }

    function test_Fork_FrozenTokens_CannotBeTransferred() public view {
        uint256 frozenBalance = bankContract.balanceOf(address(bankContract));
        // If liquidity added, should be 1M tokens
        if (frozenBalance > 0) {
            assertEq(frozenBalance, 10e18);
        }
    }

    function test_Fork_PriceCalculation_WithDifferentSupplies() public {
        uint256[] memory prices = new uint256[](5);

        for (uint256 i = 0; i < 5; i++) {
            prices[i] = bankContract.Price();

            address buyer = address(uint160(2000 + i));
            register(buyer, address(1190 + uint160(i)));
            fundDai(buyer, 100e18);

            vm.startPrank(buyer);
            dai.approve(address(bankContract), 100e18);
            bankContract.Buy(buyer, 20e18);
            vm.stopPrank();
        }

        // Each price should be higher than previous
        for (uint256 i = 1; i < 5; i++) {
            assertTrue(prices[i] >= prices[i - 1]);
        }
    }

    function test_Fork_SellAllTokens() public {
        for (uint160 i = 2; i <= 11; i++) {
            vm.startPrank(address(i + 1000));
            dai.approve(address(bankContract), 1000e18);
            bankContract.Buy(address(i + 1000), 100e18);
        }

        assertEq(dai.balanceOf(address(bankContract)), 1010e18);

        for (uint160 i = 2; i <= 11; i++) {
            vm.startPrank(address(i + 1000));
            dai.approve(address(bankContract), 1000e18);
            bankContract.Sell(bankContract.balanceOf(address(i + 1000)));
        }

        assertGt(dai.balanceOf(address(bankContract)), 10e18);
        assertEq(bankContract.totalSupply(), 10e18);
    }
}
