// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract Bee is ERC20 {

  	constructor() ERC20("Bee", "BEE") {
		_mint(msg.sender, 21000000 ether);
	}

}