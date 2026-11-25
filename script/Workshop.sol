// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {IEvaluator} from "../src/IEvaluator.sol";
import {MyToken} from "../src/MyToken.sol";

contract Ex1 is Script {
    IEvaluator constant evaluator = IEvaluator(0x05A644d6d9BBd85861ff927245aaC13bd56e6d57);

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address me = vm.addr(pk);

        vm.startBroadcast(pk);
        evaluator.ex1_getTickerAndSupply();
        vm.stopBroadcast();

        console.log(evaluator.readTicker(me));
        console.log(evaluator.readSupply(me));
    }
}

contract Ex2 is Script {
    IEvaluator constant evaluator = IEvaluator(0x05A644d6d9BBd85861ff927245aaC13bd56e6d57);

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address me = vm.addr(pk);
        string memory ticker = evaluator.readTicker(me);
        uint256 supply = evaluator.readSupply(me);
        require(bytes(ticker).length > 0, "Lancer Ex1 d'abord");

        vm.startBroadcast(pk);
        MyToken token = new MyToken("Workshop Token", ticker, supply);
        evaluator.submitExercice(address(token));
        evaluator.ex2_testErc20TickerAndSupply();
        vm.stopBroadcast();
        console.log("Token:", address(token));
    }
}

contract Ex3 is Script {
    IEvaluator constant evaluator = IEvaluator(0x05A644d6d9BBd85861ff927245aaC13bd56e6d57);

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address me = vm.addr(pk);
        string memory ticker = evaluator.readTicker(me);
        uint256 supply = evaluator.readSupply(me);

        // Nouveau déploiement : l'ancien token est déjà associé à l'Evaluator
        vm.startBroadcast(pk);
        MyToken token = new MyToken("Workshop Token", ticker, supply);
        evaluator.submitExercice(address(token));
        token.setWhiteListed(address(evaluator), true); // getToken() est réservé à la liste depuis l'ex5
        evaluator.ex3_testGetToken();
        vm.stopBroadcast();
        console.log("Token:", address(token));
    }
}

contract Ex4 is Script {
    IEvaluator constant evaluator = IEvaluator(0x05A644d6d9BBd85861ff927245aaC13bd56e6d57);

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address me = vm.addr(pk);
        string memory ticker = evaluator.readTicker(me);
        uint256 supply = evaluator.readSupply(me);

        // Nouveau déploiement : buyToken() n'existait pas dans le token précédent
        vm.startBroadcast(pk);
        MyToken token = new MyToken("Workshop Token", ticker, supply);
        evaluator.submitExercice(address(token));
        // buyToken() est réservé à la liste et aux paliers depuis l'ex7
        token.setWhiteListed(address(evaluator), true);
        token.setCustomerTier(address(evaluator), 1);
        evaluator.ex4_testBuyToken();
        vm.stopBroadcast();
        console.log("Token:", address(token));
    }
}

contract Ex5 is Script {
    IEvaluator constant evaluator = IEvaluator(0x05A644d6d9BBd85861ff927245aaC13bd56e6d57);

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address me = vm.addr(pk);
        string memory ticker = evaluator.readTicker(me);
        uint256 supply = evaluator.readSupply(me);

        // Nouveau déploiement : la liste d'autorisation n'existait pas avant.
        // L'Evaluator n'est pas ajouté à la liste, getToken() doit donc lui être refusé.
        vm.startBroadcast(pk);
        MyToken token = new MyToken("Workshop Token", ticker, supply);
        evaluator.submitExercice(address(token));
        evaluator.ex5_testDenyListing();
        vm.stopBroadcast();
        console.log("Token:", address(token));
    }
}

contract Ex6 is Script {
    IEvaluator constant evaluator = IEvaluator(0x05A644d6d9BBd85861ff927245aaC13bd56e6d57);

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address me = vm.addr(pk);

        // Pas de redéploiement : on réutilise le token soumis à l'ex5, le code n'a pas changé
        MyToken token = MyToken(evaluator.studentErc20(me));

        vm.startBroadcast(pk);
        token.setWhiteListed(address(evaluator), true);
        evaluator.ex6_testAllowListing();
        vm.stopBroadcast();
        console.log("Token:", address(token));
    }
}

contract Ex7 is Script {
    IEvaluator constant evaluator = IEvaluator(0x05A644d6d9BBd85861ff927245aaC13bd56e6d57);

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address me = vm.addr(pk);
        string memory ticker = evaluator.readTicker(me);
        uint256 supply = evaluator.readSupply(me);

        // Nouveau déploiement : les paliers n'existaient pas avant.
        // L'Evaluator n'est ni sur la liste ni dans un palier, buyToken() doit donc lui être refusé.
        vm.startBroadcast(pk);
        MyToken token = new MyToken("Workshop Token", ticker, supply);
        evaluator.submitExercice(address(token));
        evaluator.ex7_testDenyListing();
        vm.stopBroadcast();
        console.log("Token:", address(token));
    }
}

contract Ex8 is Script {
    IEvaluator constant evaluator = IEvaluator(0x05A644d6d9BBd85861ff927245aaC13bd56e6d57);

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address me = vm.addr(pk);

        // Pas de redéploiement : on réutilise le token soumis à l'ex7
        MyToken token = MyToken(evaluator.studentErc20(me));

        vm.startBroadcast(pk);
        token.setWhiteListed(address(evaluator), true);
        token.setCustomerTier(address(evaluator), 1);
        evaluator.ex8_testTier1Listing();
        vm.stopBroadcast();
        console.log("Token:", address(token));
    }
}

contract Ex9 is Script {
    IEvaluator constant evaluator = IEvaluator(0x05A644d6d9BBd85861ff927245aaC13bd56e6d57);

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address me = vm.addr(pk);

        // Même token qu'à l'ex8 : l'Evaluator compare avec la quantité achetée au palier 1
        MyToken token = MyToken(evaluator.studentErc20(me));

        vm.startBroadcast(pk);
        token.setCustomerTier(address(evaluator), 2);
        evaluator.ex9_testTier2Listing();
        vm.stopBroadcast();
        console.log("Token:", address(token));
    }
}
