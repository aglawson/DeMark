// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {DeMark} from "../src/DeMark.sol";

contract CounterTest is Test {
    DeMark public demark;

    function setUp() public {
        demark = new DeMark();
    }

}
