// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
import {IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import {ICoefficient} from "./ICoefficient.sol";

interface IERC20Minter is ICoefficient {
    /// @notice Mint token
    /// @param minterOwner The owner of minter
    /// @param minter The minter address
    /// @param deviceType The device type of minter
    /// @return Returns true for a successful mint, false for unsuccessful
    function enableDevice(
        address minterOwner,
        address minter,
        uint16 deviceType
    ) external returns (bool);

    /// @notice Suspend minter when the system detect a problem from device's action
    /// @param device The owner of minter
    function suspendDevice(address device) external;

    /// @notice Mint token
    /// @param minter The minter which will be allowed to mint
    /// @param amount The amount of tokens will be minted
    /// @param nonce The amount of tokens allowed to be used by `spender`
    /// @param v Part of signature which use for verify
    /// @param r Part of signature which use for verify
    /// @param s Part of signature which use for verify
    /// @return Returns true for a successful mint, false for unsuccessful
    function mint(
        address minter,
        uint256 amount,
        uint256 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool);

    /// @notice Get nonce of minter
    /// @param minter The minter
    function getNonce(address minter) external view returns (uint256);

    /// @notice Emitted when max of each device type change
    /// @param deviceType Device type
    /// @param value Max amount of each signature
    event ChangeLimit(uint32 indexed deviceType, uint256 value);

    /// @notice Emitted when the device was accepted to become a minter
    /// @param owner The owner of minter device
    /// @param device The address of minter device
    event EnableDevice(address indexed owner, address indexed device);

    /// @notice Emitted when the system detect a problem from device's action
    /// @param device The address of device
    event SuspendDevice(address indexed device);
}
