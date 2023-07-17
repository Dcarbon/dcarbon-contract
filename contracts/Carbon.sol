// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./ERC20Upgradeable.sol";
import "./ERC20Minter.sol";
import "./IMinter.sol";

contract Carbon is ERC20Upgradeable, ERC20Minter, UUPSUpgradeable {
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        address dcarbon_
    ) public initializer {
        __Ownable_init();
        __ERC20_init(name_, symbol_);
        __ERC20Minter_init(dcarbon_, 1e9);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyOwner {}
}
