// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

// import "@openzeppelin/contracts/utils/Counters.sol";
// import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "./ERC20Upgradeable.sol";
import "./IMinter.sol";

abstract contract ERC20Minter is
    IMinter,
    OwnableUpgradeable,
    ERC20Upgradeable,
    EIP712Upgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    bytes32 constant _MINT_TYPEHASH =
        keccak256("Mint(address iot,uint256 amount,uint256 nonce)");

    struct IOTDevice {
        bool isActived;
        uint32 deviceType;
        address owner;
        uint256 latest;
        CountersUpgradeable.Counter nonce;
    }

    mapping(bytes32 => int128) private _coefficient; //
    mapping(uint32 => uint256) private _limits; // Device type => max amount per signature
    mapping(address => IOTDevice) private _devices; // Devices address => IOT Devices (info)

    uint256 private _fee; // percent
    address private _foundation;

    uint256 public _rate;
    mapping(address => uint256) public _balaceDCarbon;
    IERC20Upgradeable public _dcarbon;

    function __ERC20Minter_init(
        address dcarbon_,
        uint256 rate_
    ) public onlyInitializing {
        _rate = rate_;
        _dcarbon = IERC20Upgradeable(dcarbon_);

        __Ownable_init_unchained();
        __EIP712_init_unchained(name(), "1");

        _fee = 5; // percent
    }

    function mint(
        address iot,
        uint256 amount,
        uint256 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public override returns (bool) {
        IOTDevice storage device = _devices[iot];

        require(device.owner != address(0) && device.isActived, "M0023");
        require(nonce == device.nonce.current() + 1, "M0001");
        require(block.timestamp - device.latest > 86400, "M0009");

        bytes32 structHash = keccak256(
            abi.encode(_MINT_TYPEHASH, iot, amount, nonce)
        );

        bytes32 hashed = _hashTypedDataV4(structHash);
        address signer = ECDSAUpgradeable.recover(hashed, v, r, s);
        require(iot == signer, "M0002");

        address receiver = getReceive(iot);
        require(receiver == _msgSender() || receiver != device.owner, "M0003");

        if (amount > _limits[device.deviceType]) {
            amount = _limits[device.deviceType];
        }
        device.nonce.increment();

        uint256 onePercent = amount / 100;
        _mintFrom(iot, receiver, onePercent * (100 - _fee));
        _mintFrom(iot, _foundation, onePercent * _fee);

        // Calculate dcarbon
        _balaceDCarbon[device.owner] += (amount * _rate) / 1e18;

        return true;
    }

    function getNonce(
        address deviceAddr
    ) public view virtual override returns (uint256) {
        IOTDevice storage device = _devices[deviceAddr];
        return device.nonce.current();
    }

    function getReceive(address iotAddr) public view returns (address) {
        return _devices[iotAddr].owner;
    }

    function getDCarbon(address owner) public view returns (uint256) {
        return _balaceDCarbon[owner];
    }

    function enableIot(
        address ownerOfProject,
        uint32 dType,
        address iotAddr
    ) public onlyOwner {
        require(iotAddr != address(0), "M0020");
        require(_limits[dType] > 0, "M0021");

        IOTDevice storage iot = _devices[iotAddr];
        require(iot.owner == address(0), "M0022");

        iot.isActived = true;
        iot.deviceType = dType;
        iot.owner = ownerOfProject;
        iot.latest = block.timestamp;
        emit EnableIOT(ownerOfProject, iotAddr);
    }

    function suspendIOT(address iot) public onlyOwner {
        _devices[iot].isActived = false;
        emit SuspendIOT(iot);
    }

    function withdrawDCarbon(uint256 amount) public {
        require(_balaceDCarbon[_msgSender()] >= amount, "M0008");

        _balaceDCarbon[_msgSender()] -= amount;
        _dcarbon.transfer(_msgSender(), amount);
    }

    function updateRate() public onlyOwner {
        _rate /= 2;
    }

    function setLimit(uint32 deviceType, uint256 limit) public onlyOwner {
        _limits[deviceType] = limit;
        emit ChangeLimit(deviceType, limit);
    }

    function setCoefficient(bytes32 key, int128 value) public onlyOwner {
        _coefficient[key] = value;
        emit ChangeCoefficient(key, value);
    }

    // function setDCarbon(address value) public onlyOwner {
    //     _coefficient[key] = value;
    //     emit ChangeCoefficient(key, value);
    // }

    event EnableIOT(address indexed owner, address indexed iot);
    event SuspendIOT(address indexed iot);

    event ChangeLimit(uint32 indexed key, uint256 value);
    event ChangeCoefficient(bytes32 indexed key, int128 value);
}
