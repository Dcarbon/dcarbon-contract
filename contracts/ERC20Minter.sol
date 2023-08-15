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

abstract contract ERC20Minter is
    IERC20Minter,
    OwnableUpgradeable,
    ERC20Upgradeable,
    EIP712Upgradeable,
    Coefficient
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // Type hash for mint (ERC712)
    bytes32 private constant _MINT_TYPEHASH =
        keccak256("Mint(address iot,uint256 amount,uint256 nonce)");

    struct MinterDevice {
        // Device status
        bool isActived;
        // Type of device
        uint16 deviceType;
        // Latest mint
        uint64 latest;
        // Owner of device
        address owner;
        // Nonce for mint signature
        CountersUpgradeable.Counter nonce;
    }

    // Device type => max amount per signature
    mapping(uint32 => uint256) private _limits;

    // Devices address => Minter Devices (info)
    // Device table
    mapping(address => MinterDevice) private _devices;

    // Balance DCarbon was minted when mint carbon
    mapping(address => uint256) public _balaceDCarbon;

    // Fee percent for foundation
    // 1 / 1e9 (1e9 equavalent 100%)
    uint128 private _fee;

    // Fee was collected
    uint128 private _feeAmount;

    // Rate to mint DCarbon when mint Carbon
    uint256 private _rate; // 1 / 1e9 (1e9 equavalent 100%)

    // DCarbon contract address
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

        // Calculate dcarbon
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

    /// @notice Withdraw DCarbon
    /// @param amount Dcarbon was withdraw
    function withdrawDCarbon(uint256 amount) public {
        require(_balaceDCarbon[_msgSender()] >= amount, "M0042");

        _balaceDCarbon[_msgSender()] -= amount;
        require(_dcarbon.transfer(_msgSender(), amount), "M0041");
    }

    /// @notice Set rate DCarbon was minted parallel with Carbon
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
    /// @param account The fee collected
    /// @return Returns the amount of DCarbon tokens owned by `account`.
    function getDCarbon(address account) public view returns (uint256) {
        return _balaceDCarbon[account];
    }

    /// @notice Emitted when the mint dcarbon rate change
    /// @param value The rate of dcarbon per each carbon was minted
    event ChangeRate(uint256 value);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount The amount of  fees that is withdrawn
    event CollectFee(address indexed recipient, uint128 amount);
}
