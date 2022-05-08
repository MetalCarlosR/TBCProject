// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import "../libs/openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../libs/openzeppelin/contracts/utils/Context.sol";


abstract contract VotingTokensERC20 is Context, ERC20{
    address owner;

    constructor(address ow){
        owner = ow;
    }

    // Modifier to check for owner
    modifier onlyOwner() {
        require(
            owner == msg.sender,
            "Only the owner of this contract can access this function"
        );
        _;
    }


    

    function addTokens(address account, uint amount) external onlyOwner {
        _mint(account, amount);
        _approve(account, owner, balanceOf(account) + amount);
    }
}