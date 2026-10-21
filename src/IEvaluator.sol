// src/IEvaluator.sol
pragma solidity ^0.8.0;

interface IEvaluator {
    function ex0_setupProject() external;
    function ex1_getTickerAndSupply() external;
    function readTicker(address) external view returns (string memory);
    function readSupply(address) external view returns (uint256);
    function submitExercice(address) external;
    function ex2_testErc20TickerAndSupply() external;
    function ex3_testGetToken() external;
    function ex4_testBuyToken() external;
}