// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract IdeaFactoryMath {
    // Constants
    uint256 public constant K = 5e14;
    uint256 public constant INITIAL_PRICE = 42700000000;

    function calculateSqrtPriceX96(uint256 price) internal pure returns (uint160) {
        uint256 adjustedPrice = price * 1e18;
        uint256 sqrtPrice = sqrt(adjustedPrice);
        uint256 sqrtPriceX96 = (sqrtPrice * (1 << 96)) / 1e18;
        require(sqrtPriceX96 <= type(uint160).max, "Price out of range");
        return uint160(sqrtPriceX96);
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function calculateCost(uint256 currentSupply, uint256 tokensToBuy) public pure returns (uint256) {
        uint256 exponent1 = (K * (currentSupply + tokensToBuy)) / 10**12;
        uint256 exponent2 = (K * currentSupply) / 10**12;
        return ((INITIAL_PRICE * 10**12 * (exp(exponent1) - exp(exponent2))) / K);
    }

    function exp(uint256 x) internal pure returns (uint256) {
        uint256 sum = 10**12;
        uint256 term = 10**12;
        
        for (uint256 i = 1; i <= 20; i++) {
            term = (term * x) / (i * 10**12);
            sum += term;
            if (term < 1) break;
        }
        
        return sum;
    }
}