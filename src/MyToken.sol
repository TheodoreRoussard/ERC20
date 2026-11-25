// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC20, Ownable {
    // ex5 : adresses autorisées à appeler getToken()
    mapping(address => bool) private whiteList;
    mapping(address => uint256) public customerTierLevel;

    // Ticker et supply sont ceux attribués par l'Evaluator (ex1), passés au déploiement
    constructor(string memory name, string memory ticker, uint256 initialSupply)
        ERC20(name, ticker)
        Ownable(msg.sender)
    {
        _mint(msg.sender, initialSupply);
    }

    // ex3 : crée des tokens pour l'appelant (ici l'Evaluator), s'il est autorisé
    function getToken() external returns (bool) {
        require(whiteList[msg.sender], "Not whitelisted");
        _mint(msg.sender, 10 * 10 ** decimals());
        return true;
    }

    // ex4 : 1 ETH = 1000 tokens (ETH et token ont tous deux 18 décimales)
    uint256 public constant TOKENS_PER_ETH = 1000;

    // ex7 : réservé à la liste, et la quantité est multipliée par le palier (palier 2 = 2x palier 1)
    function buyToken() external payable returns (bool) {
        require(whiteList[msg.sender], "Not whitelisted");
        require(customerTierLevel[msg.sender] > 0, "No authorization granted");
        require(msg.value > 0, "No ETH sent");
        _mint(msg.sender, msg.value * TOKENS_PER_ETH * customerTierLevel[msg.sender]);
        return true;
    }

    function isCustomerWhiteListed(address customerAddress) external view returns (bool) {
        return whiteList[customerAddress];
    }

    // Seul le déployeur peut modifier la liste
    function setWhiteListed(address customerAddress, bool allowed) external onlyOwner {
        whiteList[customerAddress] = allowed;
    }

    function setCustomerTier(address customerAddress, uint256 tier) external onlyOwner {
        customerTierLevel[customerAddress] = tier;
    }
}
