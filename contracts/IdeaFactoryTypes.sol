// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract IdeaFactoryTypes {
    struct IdeaTokenBase {
        string name;
        string symbol;
        string description;
        string tokenImageUrl;
        address tokenAddress;
        address creatorAddress;
        bool active;
    }

    struct IdeaTokenData {
        string productUrl;
        string categories;
        string productScreenshotUrl;
        string twitterUrl;
        string telegramUrl;
        uint256 fundingRaised;
        uint256 tokenCurrentSupply;
        uint256 creationTimestamp;
    }

    struct UpdateIdeaTokenParams {
        string description;
        string tokenImageUrl;
        string productUrl;
        string categories;
        string productScreenshotUrl;
        string twitterUrl;
        string telegramUrl;
    }

    struct CreateIdeaTokenParams {
        string name;
        string symbol;
        string imageUrl;
        string description;
        string categories;
        string productScreenshotUrl;
        string productUrl;
        string twitterUrl;
        string telegramUrl;
    }

    struct IdeaTokenFull {
        string name;
        string symbol;
        string description;
        string tokenImageUrl;
        string productUrl;
        string categories;
        string productScreenshotUrl;
        string twitterUrl;
        string telegramUrl;
        uint256 fundingRaised;
        address tokenAddress;
        address creatorAddress;
        uint256 tokenCurrentSupply;
        uint256 creationTimestamp;
        bool active;
    }

    struct MigrationState {
        bool migrationInitiated;
        uint256 migrationTimestamp;
        uint256 tokenId;
        uint128 liquidity;
        bool migrationCompleted;
    }

    struct GovernanceInfo {
        address governanceContract;
        address timelock;
        bool isInitialized;
    }

}