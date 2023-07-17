// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IMinter {
    function mint(
        address iot,
        uint256 amount,
        uint256 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool);

    function getNonce(address owner) external view returns (uint256);
}
