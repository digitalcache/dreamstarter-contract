// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./IdeaFactoryTypes.sol";

contract IdeaFactoryStorage is IdeaFactoryTypes {
    uint24 internal constant POOL_FEE = 3000;
    uint256 internal constant IDEACOIN_FUNDING_GOAL = 42001829178114400000 wei;
    uint256 public constant DECIMALS = 1e18;
    uint256 public constant MAX_SUPPLY = 1000000000 * DECIMALS;
    uint256 public constant INIT_SUPPLY = MAX_SUPPLY / 5;
    uint256 public constant MIGRATION_DELAY = 24 hours;
    uint256 internal IDEATOKEN_CREATION_FEE = 0.01 ether;

    // Uniswap addresses - polygon mainnet
    address internal immutable UNISWAP_V3_FACTORY_ADDRESS = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address internal immutable UNISWAP_V3_POSITION_MANAGER = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    address internal immutable WETH9 = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    // Sepolia addresses - mainnet
    // address internal immutable UNISWAP_V3_FACTORY_ADDRESS = 0x0227628f3F023bb0B980b67D528571c95c6DaC1c;
    // address internal immutable UNISWAP_V3_POSITION_MANAGER = 0x1238536071E1c677A632429e3655c799b22cDA52;
    // address internal immutable WETH9 = 0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;

    address[] public ideaTokenAddresses;
    mapping(address => IdeaTokenBase) public tokenBase;
    mapping(address => IdeaTokenData) public tokenData;
    mapping(address => address) public tokenToPool;
    mapping(address => MigrationState) public migrationStates;
    mapping(address => GovernanceInfo) public tokenGovernance;
}