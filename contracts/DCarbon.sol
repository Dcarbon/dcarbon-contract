// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./ERC20Upgradeable.sol";

contract DCarbon is OwnableUpgradeable, ERC20Upgradeable, UUPSUpgradeable {
    function initialize(
        address[] memory initOwner_,
        uint256[] memory amount_
    ) public initializer {
        __Ownable_init();
        __ERC20_init("DCarbon", "DCB");
        for (uint256 i = 0; i < initOwner_.length; i++) {
            _mint(initOwner_[i], amount_[i]);
        }
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyOwner {}
}
