// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Idea is ERC20 {

    address public owner;
    error OnlyOwnerCanMint();
    constructor(string memory name, string memory symbol, uint initialMintValue) ERC20(name, symbol) {
        _mint(msg.sender, initialMintValue);
        owner = msg.sender;
    }

    function mint(uint mintQty, address receiver) external returns(bool){
        if(msg.sender != owner) revert OnlyOwnerCanMint();
        _mint(receiver, mintQty);
        return true;
    }
}