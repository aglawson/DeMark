// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "../lib/forge-std/src/Test.sol";
import {DeMark} from "../src/DeMark.sol";

contract CounterTest is Test {
    DeMark public demark;

    function setUp() public {
        demark = new DeMark(10);
    }

    function test_platformFeeIs10() public {
        assertEq(10, demark.platformFee());
    }

    function test_proposeJob() public {
        demark.proposeJob("Hello, World!");
    }

}
