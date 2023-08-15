// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ICoefficient} from "./interfaces/ICoefficient.sol";

abstract contract Coefficient is ICoefficient, OwnableUpgradeable {
    mapping(bytes32 => int128) private _coefficient; //

    /// @inheritdoc ICoefficient
    function setCoefficient(bytes32 key, int128 value) public onlyOwner {
        _coefficient[key] = value;
        emit ChangeCoefficient(key, value);
    }

    /// @inheritdoc ICoefficient
    function getCoefficient(bytes32 key) public view returns (int128) {
        return _coefficient[key];
    }
}
