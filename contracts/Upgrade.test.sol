// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

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
