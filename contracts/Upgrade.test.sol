// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./ERC20Upgradeable.sol";
import "./DCarbon.sol";
import "./Carbon.sol";

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
