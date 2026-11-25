// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IEvaluator} from "./IEvaluator.sol";
import {MyToken} from "./MyToken.sol";

// ex10 : ce contrat est lui-même « l'élève ». Il part de 0 point et refait ex0 à ex9
// en son propre nom, dans une seule transaction. Les points sont crédités à ce contrat.
contract AllInOne {
    IEvaluator constant evaluator = IEvaluator(0x05A644d6d9BBd85861ff927245aaC13bd56e6d57);

    // Point d'entrée : l'Evaluator vérifie que msg.sender (ce contrat) a 0 point,
    // puis rappelle completeWorkshop(). L'ETH éventuellement envoyé recharge l'Evaluator.
    function start() external payable {
        if (msg.value > 0) {
            (bool ok,) = address(evaluator).call{value: msg.value}("");
            require(ok, "ETH transfer failed");
        }
        evaluator.ex10_allInOne();
    }

    // Appelée par l'Evaluator pendant ex10_allInOne(), même enchaînement que script/Final.sol
    function completeWorkshop() external {
        require(msg.sender == address(evaluator), "Only evaluator");
        address eval = address(evaluator);

        // ex1 dans la même transaction : personne ne peut changer le ticker entre-temps
        evaluator.ex1_getTickerAndSupply();

        // Ce contrat déploie le token, il en est donc le propriétaire (onlyOwner)
        MyToken token =
            new MyToken("Workshop Token", evaluator.readTicker(address(this)), evaluator.readSupply(address(this)));
        evaluator.submitExercice(address(token)); // valide aussi ex0 (+5 points)

        // ex2 avant tout mint : la supply doit être exacte
        evaluator.ex2_testErc20TickerAndSupply();

        token.setWhiteListed(eval, true);
        token.setCustomerTier(eval, 1);
        evaluator.ex3_testGetToken();
        evaluator.ex4_testBuyToken();

        token.setWhiteListed(eval, false);
        evaluator.ex5_testDenyListing();

        token.setWhiteListed(eval, true);
        evaluator.ex6_testAllowListing();

        token.setWhiteListed(eval, false);
        token.setCustomerTier(eval, 0);
        evaluator.ex7_testDenyListing();

        token.setWhiteListed(eval, true);
        token.setCustomerTier(eval, 1);
        evaluator.ex8_testTier1Listing();

        token.setCustomerTier(eval, 2);
        evaluator.ex9_testTier2Listing();
    }
}
