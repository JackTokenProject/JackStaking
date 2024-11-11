// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";




contract JACK is ERC20, Ownable2Step {
    error MaxSupplyExceeded();
    error OperationNotAllowed();

    uint256 constant public maxSupply = 1_000_000_000 ether;

    constructor() ERC20("JACK Token", "JACK") Ownable() {}

    function mint(address to, uint256 amount) public onlyOwner {
        if (totalSupply() + amount > maxSupply) {
            revert MaxSupplyExceeded();
        }
        _mint(to, amount);
    }

    function renounceOwnership() public virtual override onlyOwner {
        revert OperationNotAllowed();
    }
}
