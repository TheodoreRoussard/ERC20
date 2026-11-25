// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IEvaluator} from "../src/IEvaluator.sol";
import {Test} from "forge-std/Test.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {MyToken} from "../src/MyToken.sol";
import {AllInOne} from "../src/AllInOne.sol";

contract WorkshopTest is Test {
    IEvaluator evaluator = IEvaluator(0x05A644d6d9BBd85861ff927245aaC13bd56e6d57);
    IERC20 points = IERC20(0xe9b502e84D3E0A6deDB58aa61612DcB543D5eB42);
    address me;

    function setUp() public {
        // Bloc figé juste avant le passage réel sur Sepolia (ex1 validé au bloc 11963010) :
        // les tests partent toujours d'une adresse qui n'a fait que l'ex0
        vm.createSelectFork(vm.envString("SEPOLIA_RPC_URL"), 11_963_009);
        me = vm.addr(vm.envUint("PRIVATE_KEY"));
    }

    function test_ex1() public {
        uint256 before = points.balanceOf(me);

        vm.prank(me);
        evaluator.ex1_getTickerAndSupply();

        assertGt(bytes(evaluator.readTicker(me)).length, 0);
        assertGt(evaluator.readSupply(me), 0);
        assertEq(points.balanceOf(me), before + 1 ether);
    }

    function test_ex2() public {
        vm.startPrank(me);
        evaluator.ex1_getTickerAndSupply();
        uint256 before = points.balanceOf(me);

        MyToken token = new MyToken("Workshop Token", evaluator.readTicker(me), evaluator.readSupply(me));
        evaluator.submitExercice(address(token));
        uint256 afterSubmit = points.balanceOf(me);
        evaluator.ex2_testErc20TickerAndSupply();
        vm.stopPrank();

        assertEq(afterSubmit, before);
        assertEq(points.balanceOf(me), before + 2 ether);
    }

    function test_ex3() public {
        vm.startPrank(me);
        evaluator.ex1_getTickerAndSupply();
        MyToken token = new MyToken("Workshop Token", evaluator.readTicker(me), evaluator.readSupply(me));
        evaluator.submitExercice(address(token));
        token.setWhiteListed(address(evaluator), true);
        uint256 before = points.balanceOf(me);
        evaluator.ex3_testGetToken();
        vm.stopPrank();

        assertGt(token.balanceOf(address(evaluator)), 0);
        assertEq(points.balanceOf(me), before + 2 ether);
    }

    function test_ex4() public {
        vm.startPrank(me);
        evaluator.ex1_getTickerAndSupply();
        MyToken token = new MyToken("Workshop Token", evaluator.readTicker(me), evaluator.readSupply(me));
        evaluator.submitExercice(address(token));
        token.setWhiteListed(address(evaluator), true);
        token.setCustomerTier(address(evaluator), 1);
        uint256 before = points.balanceOf(me);
        evaluator.ex4_testBuyToken();
        vm.stopPrank();

        // L'Evaluator a payé 0.0001 + 0.0003 ETH
        assertEq(address(token).balance, 0.0004 ether);
        assertEq(token.balanceOf(address(evaluator)), 0.0004 ether * token.TOKENS_PER_ETH());
        assertEq(points.balanceOf(me), before + 2 ether);
    }

    function test_ex5() public {
        vm.startPrank(me);
        evaluator.ex1_getTickerAndSupply();
        MyToken token = new MyToken("Workshop Token", evaluator.readTicker(me), evaluator.readSupply(me));
        evaluator.submitExercice(address(token));
        uint256 before = points.balanceOf(me);
        evaluator.ex5_testDenyListing();
        vm.stopPrank();

        assertEq(token.balanceOf(address(evaluator)), 0);
        assertEq(points.balanceOf(me), before + 1 ether);
    }

    function test_onlyOwnerCanWhiteList() public {
        vm.prank(me);
        MyToken token = new MyToken("Workshop Token", "TKN", 1 ether);

        vm.expectRevert();
        token.setWhiteListed(address(this), true);
    }

    function test_ex6() public {
        vm.startPrank(me);
        evaluator.ex1_getTickerAndSupply();
        MyToken token = new MyToken("Workshop Token", evaluator.readTicker(me), evaluator.readSupply(me));
        evaluator.submitExercice(address(token));
        evaluator.ex5_testDenyListing();

        uint256 before = points.balanceOf(me);
        token.setWhiteListed(address(evaluator), true);
        evaluator.ex6_testAllowListing();
        vm.stopPrank();

        assertGt(token.balanceOf(address(evaluator)), 0);
        // ex6 appelle ex3_testGetToken() en interne : sur un fork neuf, l'ex3 rapporte aussi ses 2 points
        assertEq(points.balanceOf(me), before + 2 ether + 2 ether);
    }

    function test_ex7() public {
        vm.startPrank(me);
        evaluator.ex1_getTickerAndSupply();
        MyToken token = new MyToken("Workshop Token", evaluator.readTicker(me), evaluator.readSupply(me));
        evaluator.submitExercice(address(token));
        uint256 before = points.balanceOf(me);
        evaluator.ex7_testDenyListing();
        vm.stopPrank();

        assertEq(token.balanceOf(address(evaluator)), 0);
        assertEq(address(token).balance, 0);
        assertEq(points.balanceOf(me), before + 1 ether);
    }

    function test_buyTokenNeedsWhiteListAndTier() public {
        vm.prank(me);
        MyToken token = new MyToken("Workshop Token", "TKN", 1 ether);
        address buyer = makeAddr("buyer");
        vm.deal(buyer, 1 ether);

        // Palier sans liste : refusé
        vm.prank(me);
        token.setCustomerTier(buyer, 1);
        vm.prank(buyer);
        vm.expectRevert("Not whitelisted");
        token.buyToken{value: 0.1 ether}();

        // Liste + palier 1 puis palier 2 : le palier 2 donne le double
        vm.prank(me);
        token.setWhiteListed(buyer, true);
        vm.prank(buyer);
        token.buyToken{value: 0.1 ether}();
        uint256 tier1Amount = token.balanceOf(buyer);

        vm.prank(me);
        token.setCustomerTier(buyer, 2);
        vm.prank(buyer);
        token.buyToken{value: 0.1 ether}();
        assertEq(token.balanceOf(buyer) - tier1Amount, 2 * tier1Amount);
    }

    function test_ex8_ex9() public {
        vm.startPrank(me);
        evaluator.ex1_getTickerAndSupply();
        MyToken token = new MyToken("Workshop Token", evaluator.readTicker(me), evaluator.readSupply(me));
        evaluator.submitExercice(address(token));
        evaluator.ex7_testDenyListing();

        uint256 before = points.balanceOf(me);
        token.setWhiteListed(address(evaluator), true);
        token.setCustomerTier(address(evaluator), 1);
        evaluator.ex8_testTier1Listing();
        assertEq(points.balanceOf(me), before + 2 ether);

        token.setCustomerTier(address(evaluator), 2);
        evaluator.ex9_testTier2Listing();
        assertEq(points.balanceOf(me), before + 4 ether);
        vm.stopPrank();

        // Deux appels à _testBuyToken (0.0001 + 0.0003 ETH chacun)
        assertEq(address(token).balance, 0.0008 ether);
    }

    function test_ex10() public {
        AllInOne solution = new AllInOne();
        solution.start();

        // 5 (submitExercice) + 1 + 2 + 2 + 2 + 1 + 2 + 1 + 2 + 2 (ex1 à ex9) + 2 (ex10)
        assertEq(points.balanceOf(address(solution)), 22 ether);
        // Les points vont au contrat, pas à l'appelant
        assertEq(points.balanceOf(address(this)), 0);
    }

    function test_completeWorkshopOnlyEvaluator() public {
        AllInOne solution = new AllInOne();
        vm.expectRevert("Only evaluator");
        solution.completeWorkshop();
    }
}
