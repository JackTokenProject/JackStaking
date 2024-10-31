// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract JACK is ERC20Burnable, Ownable {
    uint256 constant public maxSupply = 1_000_000_000 ether;

    constructor() ERC20("JACK Token", "JACK") Ownable() {}

    function mint(address to, uint256 amount) public onlyOwner {
        require(
            totalSupply() + amount <= maxSupply,
            "JACK: minting would exceed max supply"
        );
        _mint(to, amount);
    }
}
