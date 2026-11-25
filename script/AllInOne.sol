// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {IEvaluator} from "../src/IEvaluator.sol";
import {AllInOne} from "../src/AllInOne.sol";

// ex10 : déploie AllInOne puis lance start(), en deux transactions
contract Ex10 is Script {
    IEvaluator constant evaluator = IEvaluator(0x05A644d6d9BBd85861ff927245aaC13bd56e6d57);
    uint256 constant EVALUATOR_MIN_ETH = 0.002 ether;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");

        // Même recharge que Final.sol : 3 tests d'achat à 0.0004 ETH, payés par l'Evaluator
        uint256 topUp = address(evaluator).balance < EVALUATOR_MIN_ETH ? EVALUATOR_MIN_ETH : 0;

        vm.startBroadcast(pk);
        AllInOne solution = new AllInOne();
        solution.start{value: topUp}();
        vm.stopBroadcast();

        console.log("AllInOne:", address(solution));
        require(evaluator.exerciceProgression(address(solution), 10), "ex10 non valide");
        console.log("ex10 valide");
    }
}
