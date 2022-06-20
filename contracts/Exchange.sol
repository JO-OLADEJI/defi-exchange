// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Exchange is ERC20 {

	address public beeToken;

	constructor(address _beeToken) ERC20("TastySwap LP", "TLP") {
		require(_beeToken != address(0), "NULL_TOKEN_ADDRESS");
		beeToken = _beeToken;
	}

	function getReserves() public view returns(uint256, uint256) {
		return (
			address(this).balance,
			ERC20(beeToken).balanceOf(address(this))
		);
	}

	function addLiquidity(uint256 _tokenAmount) public payable returns(uint) {
		uint256 lpTokenShare;
		uint256 beeTokenAmount;
		uint256 ethReserve;

		require(
			ERC20(beeToken).allowance(msg.sender, address(this)) >= _tokenAmount,
			"INSUFFICIENT_TOKEN_APPROVAL"
		);
		require(msg.value > 0, "NO_ETHER_SENT");
		require(_tokenAmount > 0, "NO_TOKEN_SENT");

		// first liquidity provider sets initial trading price
		(uint256 balance, uint256 tokenReserve) = getReserves();
		ethReserve = balance - msg.value;
		if (tokenReserve == 0) {
			ERC20(beeToken).transferFrom(msg.sender, address(this), _tokenAmount); // set initial ratio based on amount sent when providing liquidity
			lpTokenShare = msg.value;
		}
		else {
			beeTokenAmount = (tokenReserve * msg.value) / ethReserve;
			require(_tokenAmount >= beeTokenAmount, "INSUFFICIENT_TOKENS_SENT");
			ERC20(beeToken).transferFrom(msg.sender, address(this), beeTokenAmount); // add liquidity
			lpTokenShare = (msg.value * totalSupply()) / ethReserve;
		}

		_mint(msg.sender, lpTokenShare); // mint LP tokens to liquidity provider

		// TODO: add event to emit this information
		return lpTokenShare;
	}

	function removeLiquidity(uint256 _lpTokenAmount) public returns(uint256, uint256) {
		require(balanceOf(msg.sender) >= _lpTokenAmount, "INSUFFICIENT_LP_TOKENS");
		uint256 ethWithdrawal;
		uint256 tokenWithdrawal;
		(, uint256 tokenReserve) = getReserves();

		ethWithdrawal = (_lpTokenAmount * address(this).balance) / totalSupply();
		tokenWithdrawal = (_lpTokenAmount * tokenReserve) / totalSupply();
		_burn(msg.sender, _lpTokenAmount);
		ERC20(beeToken).transfer(msg.sender, tokenWithdrawal);
		payable(msg.sender).transfer(ethWithdrawal);
		// (bool sent, ) = address(this).call{ value: ethWithdrawal }("");
		// require(sent, "FAILED_TO_SEND_ETHER");
	
		// TODO: add event to emit this information
		return (ethWithdrawal, tokenWithdrawal);
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

		(, uint256 tokenReserve) = getReserves();
		if (msg.value > 0) { // assume eth is the input token
			inputAmountWithFees = (msg.value * 99) / 100; // fee of 1%
			outputAmount = getAmountOfTokens(inputAmountWithFees, ethReserve, tokenReserve);
			require(outputAmount >= _minOutputAmount, "INSUFFICIENT_OUTPUT_AMOUNT");
			ERC20(beeToken).transfer(msg.sender, outputAmount);
		}
		else { // assume erc20 token is the input token
			inputAmountWithFees = (_tokenAmount * 99) / 100; // fee of 1%;
			outputAmount = getAmountOfTokens(_tokenAmount, tokenReserve, ethReserve);
			require(outputAmount >= _minOutputAmount, "INSUFFICIENT_OUTPUT_AMOUNT");
			(bool sent, ) = address(this).call{ value: outputAmount }("");
			require(sent, "FAILED_TO_SEND_ETHER");
		}

		// TODO: add event to emit this information
		return outputAmount;
	}

}
