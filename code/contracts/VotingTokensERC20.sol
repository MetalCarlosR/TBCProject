// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import "../libs/openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../libs/openzeppelin/contracts/utils/Context.sol";

/**
    This version of a ERC20 system uses the concept of an admin that
    can freely manage the tokens of the users. Only usefull for a system
    like the voting where the admin of the DAO must have control of the
    votes so it can be transfered easily when a user ask for it without the need
    of the user to authorize it.

    It it used for the capibilities for the non-admin users to transfer and manage
    their tokens with other non-admin user.
 */


contract VotingTokensERC20 is Context, ERC20{
    address admin;

    constructor(address adm) ERC20("VotingToken","?") {
        admin = adm;
    }

    // Modifier to check for admin
    modifier adminOnly(){
        require(
            admin == msg.sender,
            "Only the admin of this contract can access this function"
        );
        _;
    }

    function eraseBalance(address account) public adminOnly {
        _burn(account, balanceOf(account));
    }

    function removeTokens(address account, uint amount) public adminOnly {
        _burn(account, amount);
    }
    
    function adminTrasnfer(address from, uint amount) public adminOnly {
        transferFrom(from, admin, amount);
    }

    function addTokens(address account, uint amount) public adminOnly {
        _mint(account, amount);
    }
}