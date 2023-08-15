// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

/// @title Coefficient
/// @notice IOT will get this coefficient by key to calculate amount of token
interface ICoefficient {
    /// @notice Set `value` for `key`
    /// @param key Key (Example: CH4)
    /// @param value The coefficient of the key
    function setCoefficient(bytes32 key, int128 value) external;

    /// @notice Get coefficient by key
    /// @param key Key (Example: CH4)
    function getCoefficient(bytes32 key) external returns (int128);

    /// @notice Emitted when max of each device type change
    /// @param key Device type
    /// @param value Max amount of each signature
    event ChangeCoefficient(bytes32 indexed key, int128 value);
}
