// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Exchange is ERC20 {

	address public beeToken;

	constructor(address _beeToken) ERC20("TastySwap LP", "TLP") {
		require(_beeToken != address(0), "NULL_TOKEN_ADDRESS");
		beeToken = _beeToken;
	}

	function getReserve() public view returns(uint256) {
		return ERC20(beeToken).balanceOf(address(this));
	}

	function addLiquidity(uint256 _tokenAmount) public payable returns(uint) {
		uint256 ethRatio;
		uint256 tokenRatio;
		uint256 lpTokenShare;

		require(
			ERC20(beeToken).allowance(msg.sender, address(this)) >= _tokenAmount,
			"INSUFFICIENT_TOKEN_APPROVAL"
		);
		require(msg.value > 0, "NO_ETHER_SENT");
		require(_tokenAmount > 0, "NO_TOKEN_SENT");

		// first liquidity provider sets initial trading price
		if (getReserve() == 0) {
			ERC20(beeToken).transferFrom(msg.sender, address(this), _tokenAmount); // set initial ratio based on amount sent when providing liquidity

			lpTokenShare = msg.value;
			_mint(msg.sender, lpTokenShare); // mint LP tokens to liquidity provider
		}
		else {
			ethRatio = msg.value / (address(this).balance - msg.value);
			tokenRatio = _tokenAmount / getReserve();
			require(ethRatio == tokenRatio, "INVALID_TOKEN_RATIO");
			ERC20(beeToken).transferFrom(msg.sender, address(this), _tokenAmount); // add liquidity based on ratio

			lpTokenShare = ethRatio * totalSupply();
			_mint(msg.sender, lpTokenShare); // mint LP tokens to liquidity provider
		}

		return lpTokenShare;
	}

	function removeLiquidity(uint256 _lpTokenAmount) public returns(uint256, uint256) {
		uint256 removalRatio;

		require(balanceOf(msg.sender) >= _lpTokenAmount, "INSUFFICIENT_LP_TOKENS");
		removalRatio = _lpTokenAmount / totalSupply();
		uint256 ethRefund = removalRatio * address(this).balance;
		uint256 tokenRefund = removalRatio * getReserve();

		_burn(msg.sender, _lpTokenAmount);
		ERC20(beeToken).transfer(msg.sender, tokenRefund);
		(bool sent, ) = address(this).call{ value: ethRefund }("");
		require(sent, "FAILED_TO_SEND_ETHER");

		return (ethRefund, tokenRefund);
	}

	function getAmountOfTokens(
		uint256 _inputAmount,
		uint256 _inputReserve,
		uint256 _outputReserve
	) public pure returns(uint256) {
		require(_inputReserve > 0 && _outputReserve > 0, "INVALID_RESERVES");
		return _outputReserve - ((_inputReserve * _outputReserve) / _inputReserve + _inputAmount);
	}

	function swap(uint256 _tokenAmount, uint256 _minOutputAmount) public payable returns(uint256) {
		uint256 inputAmountWithFees;
		uint256 outputAmount;
		uint256 ethReserve;

		require(msg.value > 0 || _tokenAmount > 0, "NULL_INPUT_AMOUNT");
		ethReserve = address(this).balance - msg.value;

		if (msg.value > 0) { // assume eth is the input token
			inputAmountWithFees = (msg.value * 99) / 100; // fee of 1%
			outputAmount = getAmountOfTokens(inputAmountWithFees, ethReserve, getReserve());
			require(outputAmount >= _minOutputAmount, "INSUFFICIENT_OUTPUT_AMOUNT");
			ERC20(beeToken).transfer(msg.sender, outputAmount);
		}
		else { // assume erc20 token is the input token
			inputAmountWithFees = (_tokenAmount * 99) / 100; // fee of 1%;
			outputAmount = getAmountOfTokens(_tokenAmount, getReserve(), ethReserve);
			require(outputAmount >= _minOutputAmount, "INSUFFICIENT_OUTPUT_AMOUNT");
			(bool sent, ) = address(this).call{ value: outputAmount }("");
			require(sent, "FAILED_TO_SEND_ETHER");
		}

		return outputAmount;
	}

}
