// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {ERC20Upgradeable} from "./ERC20Upgradeable.sol";
import {ERC20Minter} from "./ERC20Minter.sol";
import {IERC20Minter} from "./interfaces/IERC20Minter.sol";

import {DCarbon} from "./DCarbon.sol";
import {Carbon} from "./Carbon.sol";

contract DCarbon2 is DCarbon {
    function hello() public pure returns (string memory) {
        return "hello_dcarbon_2";
    }
}

contract CarbonTest2 is Carbon {
    function hello() public pure returns (string memory) {
        return "hello_carbon_2";
    }
}
