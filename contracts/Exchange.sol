// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Exchange is ERC20 {
    address public beeToken;

    event LiquidityAdded(
        address indexed pair,
        address indexed liquidityProvider,
        uint256 ethAmountIn,
        uint256 tokenAmountIn
    );

    event LiquidityRemoved(
        address indexed pair,
        address indexed liquidityProvider,
        uint256 ethAmountOut,
        uint256 tokenAmountOut
    );

    event Swap(
        address indexed pair,
        address indexed sender,
        uint256 ethAmountIn,
        uint256 ethAmountOut,
        uint256 tokenAmountIn,
        uint256 tokenAmountOut
    );

    constructor(address _beeToken) ERC20("TastySwap LP", "TLP") {
        require(_beeToken != address(0), "NULL_TOKEN_ADDRESS");
        beeToken = _beeToken;
    }

    function getReserves() public view returns (uint256, uint256) {
        return (
            address(this).balance,
            ERC20(beeToken).balanceOf(address(this))
        );
    }

    function addLiquidity(uint256 _tokenAmount)
        public
        payable
        returns (uint256)
    {
        uint256 lpTokenShare;
        uint256 beeTokenAmount;
        uint256 ethReserve;

        require(
            ERC20(beeToken).allowance(msg.sender, address(this)) >=
                _tokenAmount,
            "INSUFFICIENT_TOKEN_APPROVAL"
        );
        require(msg.value > 0, "NO_ETHER_SENT");
        require(_tokenAmount > 0, "NO_TOKEN_SENT");

        // first liquidity provider sets initial trading price
        (uint256 balance, uint256 tokenReserve) = getReserves();
        ethReserve = balance - msg.value;
        if (tokenReserve == 0) {
            beeTokenAmount = _tokenAmount;
            ERC20(beeToken).transferFrom(
                msg.sender,
                address(this),
                beeTokenAmount
            ); // set initial ratio based on amount sent when providing liquidity
            lpTokenShare = msg.value;
        } else {
            beeTokenAmount = (tokenReserve * msg.value) / ethReserve;
            require(_tokenAmount >= beeTokenAmount, "INSUFFICIENT_TOKENS_SENT");
            ERC20(beeToken).transferFrom(
                msg.sender,
                address(this),
                beeTokenAmount
            ); // add liquidity
            lpTokenShare = (msg.value * totalSupply()) / ethReserve;
        }

        _mint(msg.sender, lpTokenShare); // mint LP tokens to liquidity provider
        emit LiquidityAdded(
            address(this),
            msg.sender,
            msg.value,
            beeTokenAmount
        );

        return lpTokenShare;
    }

    function removeLiquidity(uint256 _lpTokenAmount)
        public
        returns (uint256, uint256)
    {
        require(
            balanceOf(msg.sender) >= _lpTokenAmount,
            "INSUFFICIENT_LP_TOKENS"
        );
        uint256 ethWithdrawal;
        uint256 tokenWithdrawal;
        (, uint256 tokenReserve) = getReserves();

        ethWithdrawal =
            (_lpTokenAmount * address(this).balance) /
            totalSupply();
        tokenWithdrawal = (_lpTokenAmount * tokenReserve) / totalSupply();
        _burn(msg.sender, _lpTokenAmount);
        ERC20(beeToken).transfer(msg.sender, tokenWithdrawal);
        payable(msg.sender).transfer(ethWithdrawal);
        emit LiquidityRemoved(
            address(this),
            msg.sender,
            ethWithdrawal,
            tokenWithdrawal
        );

        return (ethWithdrawal, tokenWithdrawal);
    }

    function getAmountOfTokens(
        uint256 _inputAmount,
        uint256 _inputReserve,
        uint256 _outputReserve
    ) public pure returns (uint256) {
        require(_inputReserve > 0 && _outputReserve > 0, "INVALID_RESERVES");
        uint256 inputAmountWithFee = _inputAmount * 99; // fee of 1%
        // (x + Δx) * (y - Δy) = x * y
        uint256 numerator = inputAmountWithFee * _outputReserve;
        uint256 denominator = (_inputReserve * 100) + inputAmountWithFee;
        return numerator / denominator;
    }

    function swap(uint256 _tokenAmount, uint256 _minOutputAmount)
        public
        payable
        returns (uint256)
    {
        uint256 outputAmount;
        uint256 ethReserve;

        require(msg.value > 0 || _tokenAmount > 0, "NULL_INPUT_AMOUNT");
        ethReserve = address(this).balance - msg.value;

        (, uint256 tokenReserve) = getReserves();
        if (msg.value > 0) {
            // assume eth is the input
            outputAmount = getAmountOfTokens(
                msg.value,
                ethReserve,
                tokenReserve
            );
            require(
                outputAmount >= _minOutputAmount,
                "INSUFFICIENT_OUTPUT_AMOUNT"
            );
            ERC20(beeToken).transfer(msg.sender, outputAmount);
            emit Swap(address(this), msg.sender, msg.value, 0, 0, outputAmount);
        } else {
            // take erc20 token is the input
            outputAmount = getAmountOfTokens(
                _tokenAmount,
                tokenReserve,
                ethReserve
            );
            require(
                outputAmount >= _minOutputAmount,
                "INSUFFICIENT_OUTPUT_AMOUNT"
            );
            ERC20(beeToken).transferFrom(
                msg.sender,
                address(this),
                _tokenAmount
            );
            payable(msg.sender).transfer(outputAmount);
            emit Swap(
                address(this),
                msg.sender,
                0,
                outputAmount,
                _tokenAmount,
                0
            );
        }

        return outputAmount;
    }
}
