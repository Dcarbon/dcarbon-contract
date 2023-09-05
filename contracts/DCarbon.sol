// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {ERC20Upgradeable} from "./ERC20Upgradeable.sol";

contract DCarbon is OwnableUpgradeable, ERC20Upgradeable, UUPSUpgradeable {
    function initialize(
        address[] memory initOwner_,
        uint256[] memory amount_
    ) public initializer {
        __Ownable_init();
        initERC20Upgradeable("DCarbon", "DCB");
        for (uint256 i = 0; i < initOwner_.length; i++) {
            _mint(initOwner_[i], amount_[i]);
        }
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyOwner {}
}
