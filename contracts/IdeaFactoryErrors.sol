// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract IdeaFactoryErrors {
    error InsufficientCreationFee(uint256 provided, uint256 required);
    error UnauthorizedCaller(address caller, address owner);
    error TokenNotFound(address tokenAddress);
    error TokenNotActive(address tokenAddress);
    error FundingGoalReached(uint256 raised, uint256 goal);
    error InsufficientAvailableSupply(uint256 requested, uint256 available);
    error InsufficientEthSent(uint256 sent, uint256 required);
    error PoolCreationFailed(address token0, address token1);
    error PoolInitializationFailed(address pool);
    error CantAcceptDonation();
    error NotTokenCreator(address caller, address creator);
}