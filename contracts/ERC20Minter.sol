// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

// import "@openzeppelin/contracts/utils/Counters.sol";
// import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {EIP712Upgradeable, ECDSAUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import {IERC20Minter} from "./interfaces/IERC20Minter.sol";
import {ERC20Upgradeable} from "./ERC20Upgradeable.sol";
import {Coefficient} from "./Coefficient.sol";

/**
 * @dev This contract manages the minting process of the CARBON token by verifying the IoT device data through 
 * EIP-712 data hashing and signing standard.
 * 
 * Each IoT device holds a private key which can be used to sign off sensor data. The private key is presumably unknown even to
 * its producer and cannot be extracted by any means.
 * 
 * To prevent the contract from replay attacks, a nonce number set for each IoT device and will be increased each time the
 * mint() function is executed.
 * 
 * This contract also implements a function to withdraw associated locked DCARBON tokens when minting CARBONs.
 */

abstract contract ERC20Minter is
    IERC20Minter,
    OwnableUpgradeable,
    ERC20Upgradeable,
    EIP712Upgradeable,
    Coefficient
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // Type hash for mint (EIP-712)
    bytes32 private constant _MINT_TYPEHASH =
        keccak256("Mint(address iot,uint256 amount,uint256 nonce)");

    struct MinterDevice {
        // IoT device status
        bool isActived;
        // Type of IoT device
        uint16 deviceType;
        // Latest mint time
        uint64 latest;
        // Owner of the IoT device
        address owner;
        // Current nonce of the IoT device
        CountersUpgradeable.Counter nonce;
    }

    // IoT Device type => max amount for a signature
    mapping(uint32 => uint256) private _limits;

    // IoT Devices address => Minter IoT Devices (info)
    // IoT Device hash table
    mapping(address => MinterDevice) private _devices;

    // Balance of the associated DCARBON was unlocked when mint CARBON
    mapping(address => uint256) public _balaceDCarbon;

    // Fee percent for the Dcarbon foundation
    // 1 / 1e9 (1e9 equavalent 100%)
    uint128 private _fee;

    // Current collected fee
    uint128 private _feeAmount;

    // unlock rate for DCARBON when mint CARBON
    uint256 private _rate; // 1 / 1e9 (1e9 equavalent 100%)

    // DCARBON token contract address
    IERC20Upgradeable public _dcarbon;

    // Initialize
    function __ERC20Minter_init(
        address dcarbon,
        uint256 rate_
    ) internal onlyInitializing {
        _rate = rate_;
        _dcarbon = IERC20Upgradeable(dcarbon);

        __Ownable_init_unchained();
        __EIP712_init_unchained(name(), "1");

        _fee = 5 * 1e7;
    }

    /// @inheritdoc IERC20Minter
    function mint(
        address minter,
        uint256 amount,
        uint256 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public override returns (bool) {
        MinterDevice storage device = _devices[minter];

        require(device.owner != address(0) && device.isActived, "M0023");
        require(nonce == device.nonce.current() + 1, "M0001");
        require(block.timestamp - device.latest > 86400, "M0009");

        bytes32 structHash = keccak256(
            abi.encode(_MINT_TYPEHASH, minter, amount, nonce)
        );

        bytes32 hashed = _hashTypedDataV4(structHash);
        address signer = ECDSAUpgradeable.recover(hashed, v, r, s);
        require(minter == signer, "M0002");

        require(
            device.owner == _msgSender() || device.owner != device.owner,
            "M0003"
        );

        if (amount > _limits[device.deviceType]) {
            amount = _limits[device.deviceType];
        }
        device.nonce.increment();

        uint256 mintFee = (amount * _fee) / 1e9;

        _feeAmount += uint128(mintFee);
        _mintFrom(minter, device.owner, amount - mintFee);

        // Calculate DCARBON
        _balaceDCarbon[device.owner] += (amount * _rate) / 1e9;

        return true;
    }

    /// @inheritdoc IERC20Minter
    function getNonce(
        address deviceAddr
    ) public view virtual override returns (uint256) {
        MinterDevice storage device = _devices[deviceAddr];
        return device.nonce.current();
    }

    /// @inheritdoc IERC20Minter
    function enableDevice(
        address minterOwner,
        address deviceAddress,
        uint16 deviceType
    ) public onlyOwner returns (bool) {
        require(deviceAddress != address(0), "M0020");
        require(_limits[deviceType] > 0, "M0021");

        MinterDevice storage device = _devices[deviceAddress];
        require(device.owner == address(0), "M0100");

        device.isActived = true;
        device.deviceType = deviceType;
        device.owner = minterOwner;
        device.latest = uint64(block.timestamp);
        emit EnableDevice(minterOwner, deviceAddress);

        return true;
    }

    /// @inheritdoc IERC20Minter
    function suspendDevice(address device) public onlyOwner {
        _devices[device].isActived = false;
        emit SuspendDevice(device);
    }

    /// @notice Withdraw unlocked DCARBON
    /// @param amount DCARBON to be withdrawn
    function withdrawDCarbon(uint256 amount) public {
        require(_balaceDCarbon[_msgSender()] >= amount, "M0042");

        _balaceDCarbon[_msgSender()] -= amount;
        require(_dcarbon.transfer(_msgSender(), amount), "M0041");
    }

    /// @notice Set unlock rate for DCARBON when minting CARBON
    /// @param rate The address to which collected protocol fees should be sent
    function setRate(uint256 rate) public onlyOwner {
        require(rate < 1e9, "M0040");
        _rate = rate;
        emit ChangeRate(rate);
    }

    /// @notice Set `limit` for `deviceType`
    /// @param deviceType Type of device was set
    /// @param limit Limit value
    function setLimit(uint32 deviceType, uint256 limit) public onlyOwner {
        _limits[deviceType] = limit;
        emit ChangeLimit(deviceType, limit);
    }

    /// @notice Collect the fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount The fee collected
    function collectFee(address recipient, uint128 amount) public onlyOwner {
        uint256 fee = _feeAmount;
        require(recipient != address(0), "M030");
        require(amount <= fee, "");

        _feeAmount -= amount;
        _mint(recipient, amount);
        emit CollectFee(recipient, amount);
    }

    /// @notice Get DCarbon balance of `account`
    /// @param account address to get the balance
    /// @return Returns the amount of DCarbon tokens owned by `account`.
    function getDCarbon(address account) public view returns (uint256) {
        return _balaceDCarbon[account];
    }

    /// @notice Emitted when the DCARBON unlock rate is changed
    /// @param value The unlock rate of DCARBON per each carbon was minted
    event ChangeRate(uint256 value);

    /// @notice Emitted when the collected protocol fees are withdrawn by the project owner
    /// @param recipient The address that will receive the collected protocol fees
    /// @param amount The amount of fees that is withdrawn
    event CollectFee(address indexed recipient, uint128 amount);
}
