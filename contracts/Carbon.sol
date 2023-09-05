// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {ERC20Upgradeable} from "./ERC20Upgradeable.sol";
import {ERC20Minter} from "./ERC20Minter.sol";
import {IERC20Minter} from "./interfaces/IERC20Minter.sol";

contract Carbon is IERC20Minter, ERC20Minter, UUPSUpgradeable {
    function initialize(
        string memory name_,
        string memory symbol_,
        address dcarbon_
    ) public initializer {
        __Ownable_init();
        initERC20Upgradeable(name_, symbol_);
        initERC20Minter(dcarbon_, 5e8);
    }

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyOwner {}
}
