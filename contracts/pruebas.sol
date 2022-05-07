// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

contract Pruebas{
    
    uint money;

    constructor(){
        money = 0;
    }

    function algo() external payable{

    }

    function dinero()public view returns(uint) {
        return money;
    }
}