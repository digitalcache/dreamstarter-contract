// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "./Idea.sol";
import "./IdeaFactoryStorage.sol";
import "./IdeaFactoryMath.sol";
import "./IdeaFactoryErrors.sol";


contract IdeaFactoryLiquidity is IdeaFactoryStorage, IdeaFactoryMath, IdeaFactoryErrors {
    function _createLiquidityPool(address ideaTokenAddress) internal returns (address, uint160) {
        IUniswapV3Factory factory = IUniswapV3Factory(UNISWAP_V3_FACTORY_ADDRESS);
        
        address token0 = ideaTokenAddress < WETH9 ? ideaTokenAddress : WETH9;
        address token1 = ideaTokenAddress < WETH9 ? WETH9 : ideaTokenAddress;
        
        address pool = factory.createPool(token0, token1, POOL_FEE);
        if (pool == address(0)) {
            revert PoolCreationFailed(token0, token1);
        }
        
        IUniswapV3Pool uniswapV3Pool = IUniswapV3Pool(pool);
        uint256 priceAtFundingGoal = (INIT_SUPPLY * 1e18 ) / IDEACOIN_FUNDING_GOAL;
        // uint256 priceAtFundingGoal = (IDEACOIN_FUNDING_GOAL * 1e18 ) / INIT_SUPPLY;


        uint160 sqrtPriceX96 = calculateSqrtPriceX96(priceAtFundingGoal);
        uniswapV3Pool.initialize(sqrtPriceX96);

        tokenToPool[ideaTokenAddress] = pool;
        emit PoolCreated(token0, token1, pool, sqrtPriceX96);
        emit SquareRootPrice(sqrtPriceX96);
        return (pool, sqrtPriceX96);
    }

    function _provideLiquidity(address ideaTokenAddress, uint256 ethAmount, address _owner) 
        internal 
        returns (uint128) 
    {
        uint256 tokenAmount = INIT_SUPPLY;
        Idea ideaToken = Idea(ideaTokenAddress);
        ideaToken.approve(UNISWAP_V3_POSITION_MANAGER, tokenAmount);
        INonfungiblePositionManager positionManager = INonfungiblePositionManager(UNISWAP_V3_POSITION_MANAGER);

        address token0 = ideaTokenAddress < WETH9 ? ideaTokenAddress : WETH9;
        address token1 = ideaTokenAddress < WETH9 ? WETH9 : ideaTokenAddress;

        uint256 amount0 = ideaTokenAddress < WETH9 ? tokenAmount : ethAmount;
        uint256 amount1 = ideaTokenAddress < WETH9 ? ethAmount : tokenAmount;

        INonfungiblePositionManager.MintParams memory params = _prepareMintParams(
            token0, 
            token1, 
            amount0, 
            amount1,
            _owner
        );

        positionManager.mint{value: ethAmount}(params);

        return 1;
    }
    
    function _prepareMintParams(
        address token0, 
        address token1, 
        uint256 amount0Desired, 
        uint256 amount1Desired,
        address _owner
    ) private view returns (INonfungiblePositionManager.MintParams memory) {
            int24 TICK_SPACING = 60;
            int24 tickRange = 10000;

            address poolAddress = tokenToPool[token0 == WETH9 ? token1 : token0];
            IUniswapV3Pool pool = IUniswapV3Pool(poolAddress);
            (, int24 currentTick,,,,,) = pool.slot0();
            
            int24 tickLower = ((currentTick - tickRange) / TICK_SPACING) * TICK_SPACING;
            int24 tickUpper = ((currentTick + tickRange) / TICK_SPACING) * TICK_SPACING;
            
            tickLower = tickLower < TickMath.MIN_TICK ? TickMath.MIN_TICK : tickLower;
            tickUpper = tickUpper > TickMath.MAX_TICK ? TickMath.MAX_TICK : tickUpper;

        return INonfungiblePositionManager.MintParams({
            token0: token0,
            token1: token1,
            fee: POOL_FEE,
            tickLower: tickLower,
            tickUpper: tickUpper,
            amount0Desired: amount0Desired,
            amount1Desired: amount1Desired,
            amount0Min: 0,
            amount1Min: 0,
            recipient: _owner,
            deadline: block.timestamp
        });
    }

    event PoolCreated(
        address indexed token0,
        address indexed token1,
        address pool,
        uint160 sqrtPriceX96
    );
    event SquareRootPrice(uint256 price);
    event LiquidityProvided(
        address indexed token,
        uint256 tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );

    event ParamsPositionManager(
        address indexed token0,
        address indexed token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0Min,
        uint256 amount1Min,
        address recipient
    );
}