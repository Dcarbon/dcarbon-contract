// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {ERC20Upgradeable} from "./ERC20Upgradeable.sol";
import {ERC20Minter} from "./ERC20Minter.sol";
import {IMinter} from "./IMinter.sol";

contract Carbon is ERC20Upgradeable, ERC20Minter, UUPSUpgradeable {
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        address foundation_,
        address dcarbon_
    ) public initializer {
        __Ownable_init();
        __ERC20_init(name_, symbol_);
        __ERC20Minter_init(foundation_, dcarbon_, 5e8);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyOwner {}
}
