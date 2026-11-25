// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {IEvaluator} from "../src/IEvaluator.sol";
import {MyToken} from "../src/MyToken.sol";

// Enchaîne les ex2 à ex9 sur un seul token.
// Prérequis : avoir lancé Ex1 (script/Workshop.sol) une seule fois, dans une transaction à part.
// Si ex1 et ex2 partaient ensemble, un autre élève pourrait appeler ex1 entre la simulation
// et l'exécution : le ticker réellement attribué ne serait plus celui du token déployé.
contract Final is Script {
    IEvaluator constant evaluator = IEvaluator(0x05A644d6d9BBd85861ff927245aaC13bd56e6d57);

    // 3 tests d'achat (ex4, ex8, ex9) à 0.0004 ETH chacun, payés par l'Evaluator
    uint256 constant EVALUATOR_MIN_ETH = 0.002 ether;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address me = vm.addr(pk);
        address eval = address(evaluator);

        string memory ticker = evaluator.readTicker(me);
        uint256 supply = evaluator.readSupply(me);
        require(evaluator.exerciceProgression(me, 1) && bytes(ticker).length > 0, "Lancer Ex1 d'abord");
        console.log("Ticker:", ticker);
        console.log("Supply:", supply);

        vm.startBroadcast(pk);

        // Le solde de l'Evaluator est partagé entre tous les élèves : on le complète si besoin
        if (eval.balance < EVALUATOR_MIN_ETH) {
            (bool ok,) = eval.call{value: EVALUATOR_MIN_ETH}("");
            require(ok, "Envoi d'ETH a l'Evaluator echoue");
        }

        MyToken token = new MyToken("Workshop Token", ticker, supply);
        evaluator.submitExercice(address(token));

        // ex2 en premier : totalSupply doit être exactement la supply attribuée, avant tout mint
        evaluator.ex2_testErc20TickerAndSupply();

        // ex3, ex4 : Evaluator autorisé, palier 1
        token.setWhiteListed(eval, true);
        token.setCustomerTier(eval, 1);
        evaluator.ex3_testGetToken();
        evaluator.ex4_testBuyToken();

        // ex5 : retiré de la liste, getToken() doit échouer
        token.setWhiteListed(eval, false);
        evaluator.ex5_testDenyListing();

        // ex6 : de retour sur la liste, getToken() doit fonctionner
        token.setWhiteListed(eval, true);
        evaluator.ex6_testAllowListing();

        // ex7 : ni liste ni palier, buyToken() doit échouer
        token.setWhiteListed(eval, false);
        token.setCustomerTier(eval, 0);
        evaluator.ex7_testDenyListing();

        // ex8 : liste + palier 1, l'Evaluator mémorise la quantité achetée
        token.setWhiteListed(eval, true);
        token.setCustomerTier(eval, 1);
        evaluator.ex8_testTier1Listing();

        // ex9 : palier 2, même prix, exactement le double
        token.setCustomerTier(eval, 2);
        evaluator.ex9_testTier2Listing();

        vm.stopBroadcast();

        console.log("Token:", address(token));
        for (uint256 i = 0; i <= 9; i++) {
            require(evaluator.exerciceProgression(me, i), "Un exercice n'est pas valide");
        }
        console.log("ex0 a ex9 valides");
    }
}
