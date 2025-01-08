// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./IdeaFactoryStorage.sol";
import "./IdeaFactoryLiquidity.sol";
import "./IdeaFactoryErrors.sol";
import "./Idea.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract IdeaFactory is IdeaFactoryLiquidity, ReentrancyGuard, Pausable, Ownable {
    constructor() Ownable() {
    }

    function createIdeaToken(CreateIdeaTokenParams calldata params) 
        external 
        payable 
        nonReentrant 
        whenNotPaused 
        returns (address) 
    {
        if (msg.value < IDEATOKEN_CREATION_FEE) {
            revert InsufficientCreationFee({
                provided: msg.value,
                required: IDEATOKEN_CREATION_FEE
            });
        }
        
        Idea newToken = new Idea(params.name, params.symbol, INIT_SUPPLY);
        address ideaTokenAddress = address(newToken);
        ideaTokenAddresses.push(ideaTokenAddress);
        
        tokenBase[ideaTokenAddress] = IdeaTokenBase({
            name: params.name,
            symbol: params.symbol,
            description: params.description,
            tokenImageUrl: params.imageUrl,
            tokenAddress: ideaTokenAddress,
            creatorAddress: msg.sender,
            active: true
        });

        tokenData[ideaTokenAddress] = IdeaTokenData({
            productUrl: params.productUrl,
            categories: params.categories,
            productScreenshotUrl: params.productScreenshotUrl,
            twitterUrl: params.twitterUrl,
            telegramUrl: params.telegramUrl,
            fundingRaised: 0,
            tokenCurrentSupply: INIT_SUPPLY,
            creationTimestamp: block.timestamp
        });

        return ideaTokenAddress;
    }

    function buyIdeaToken(address ideaTokenAddress, uint256 tokenQty) 
        external 
        payable 
        nonReentrant
        whenNotPaused
        returns (bool) 
    {
        IdeaTokenBase storage base = tokenBase[ideaTokenAddress];
        if (base.tokenAddress == address(0)) revert TokenNotFound(ideaTokenAddress);
        if (!base.active) revert TokenNotActive(ideaTokenAddress);
        
        IdeaTokenData storage data = tokenData[ideaTokenAddress];
        if (data.fundingRaised > IDEACOIN_FUNDING_GOAL) {
            revert FundingGoalReached({
                raised: data.fundingRaised,
                goal: IDEACOIN_FUNDING_GOAL
            });
        }
        
        Idea ideaTokenCt = Idea(ideaTokenAddress);
        uint256 currentSupply = ideaTokenCt.totalSupply();
        
        uint256 available_qty = MAX_SUPPLY - currentSupply;
        if (tokenQty > available_qty) {
            revert InsufficientAvailableSupply({
                requested: tokenQty,
                available: available_qty
            });
        }

        uint256 currentSupplyScaled = (currentSupply - INIT_SUPPLY) / DECIMALS;
        uint256 tokenQtyScaled = tokenQty * DECIMALS;
        uint256 requiredEth = calculateCost(currentSupplyScaled, tokenQty);

        if (msg.value < requiredEth) {
            revert InsufficientEthSent({
                sent: msg.value,
                required: requiredEth
            });
        }

        data.fundingRaised += msg.value;
        data.tokenCurrentSupply = currentSupply + tokenQtyScaled;
        if(data.fundingRaised >= IDEACOIN_FUNDING_GOAL) {
            _createLiquidityPool(ideaTokenAddress);
            _provideLiquidity(ideaTokenAddress, data.fundingRaised, owner());
        }

        ideaTokenCt.mint(tokenQtyScaled, msg.sender);
        return true;
    }

    function getAllIdeaTokens() external view returns (IdeaTokenFull[] memory) {
        IdeaTokenFull[] memory allTokens = new IdeaTokenFull[](ideaTokenAddresses.length);
        for (uint i = 0; i < ideaTokenAddresses.length; i++) {
            address tokenAddress = ideaTokenAddresses[i];
            IdeaTokenBase storage base = tokenBase[tokenAddress];
            IdeaTokenData storage data = tokenData[tokenAddress];
            
            allTokens[i] = IdeaTokenFull({
                name: base.name,
                symbol: base.symbol,
                description: base.description,
                tokenImageUrl: base.tokenImageUrl,
                productUrl: data.productUrl,
                categories: data.categories,
                productScreenshotUrl: data.productScreenshotUrl,
                twitterUrl: data.twitterUrl,
                telegramUrl: data.telegramUrl,
                fundingRaised: data.fundingRaised,
                tokenAddress: base.tokenAddress,
                creatorAddress: base.creatorAddress,
                tokenCurrentSupply: data.tokenCurrentSupply,
                creationTimestamp: data.creationTimestamp,
                active: base.active
            });
        }
        return allTokens;
    }

    function getIdeaToken(address ideaTokenAddress) external returns (IdeaTokenFull memory) {
        IdeaTokenBase storage base = tokenBase[ideaTokenAddress];
        if (base.tokenAddress == address(0)) revert TokenNotFound(ideaTokenAddress);
        
        IdeaTokenData storage data = tokenData[ideaTokenAddress];
        Idea ideaTokenCt = Idea(ideaTokenAddress);
        data.tokenCurrentSupply = ideaTokenCt.totalSupply();

        return IdeaTokenFull({
            name: base.name,
            symbol: base.symbol,
            description: base.description,
            tokenImageUrl: base.tokenImageUrl,
            productUrl: data.productUrl,
            categories: data.categories,
            productScreenshotUrl: data.productScreenshotUrl,
            twitterUrl: data.twitterUrl,
            telegramUrl: data.telegramUrl,
            fundingRaised: data.fundingRaised,
            tokenAddress: base.tokenAddress,
            creatorAddress: base.creatorAddress,
            tokenCurrentSupply: data.tokenCurrentSupply,
            creationTimestamp: data.creationTimestamp,
            active: base.active
        });
    }

    function updateIdeaToken(address ideaTokenAddress, UpdateIdeaTokenParams calldata params)
        external
        nonReentrant
        whenNotPaused
        returns (bool)
    {
        IdeaTokenBase storage base = tokenBase[ideaTokenAddress];
        if (base.tokenAddress == address(0)) revert TokenNotFound(ideaTokenAddress);
        if (!base.active) revert TokenNotActive(ideaTokenAddress);
        if (msg.sender != base.creatorAddress) revert NotTokenCreator(msg.sender, base.creatorAddress);

        base.description = params.description;
        base.tokenImageUrl = params.tokenImageUrl;

        IdeaTokenData storage data = tokenData[ideaTokenAddress];
        data.productUrl = params.productUrl;
        data.categories = params.categories;
        data.productScreenshotUrl = params.productScreenshotUrl;
        data.twitterUrl = params.twitterUrl;
        data.telegramUrl = params.telegramUrl;
        return true;
    }

    function setCreationFeeInWei(uint256 newFee) 
        external 
        onlyOwner 
        nonReentrant 
        whenNotPaused 
        returns (bool) 
    {
        IDEATOKEN_CREATION_FEE = newFee;
        return true;
    }

    function setIdeaStatus(address ideaTokenAddress, bool newStatus) 
        external
        onlyOwner
        nonReentrant
        whenNotPaused
        returns (bool)
    {
        IdeaTokenBase storage base = tokenBase[ideaTokenAddress];
        if (base.tokenAddress == address(0)) revert TokenNotFound(ideaTokenAddress);
        base.active = newStatus;
        return true;
    }

    function withdraw() external onlyOwner nonReentrant {
        uint256 amount = address(this).balance;
        (bool success, ) = owner().call{value: amount}("");
        require(success, "Withdrawal failed");
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    receive() external payable {
        revert CantAcceptDonation();
    }
}