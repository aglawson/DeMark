// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "../lib/forge-std/src/Test.sol";
import {DeMark} from "../src/DeMark.sol";

    error AlreadyCompletedOrCanceled();
    error NotProposer();
    error NotCompletor();
    error MustBeBetweenOneAndFiveInclusive();
    error AlreadyRated();
    error PayoutLowerThan100Wei();
    error ProposerCannotSubmit();
    error AlreadySubmitted();
    error NotContract();
    error ContractNotBuyable();
    error NotASubmission();
    error SenderNotContractOwner();
    error OwnableUnauthorizedAccount(address account);

contract CounterTest is Test {
    DeMark public demark;

    function setUp() public {
        demark = new DeMark(10);
    }

    function test_platformFeeIs10() public {
        assertEq(10, demark.platformFee());
    }

    function test_proposeJob() public {
        demark.proposeJob{value: 1000000000000000000}("Hello, World!");
    }

    function test_RevertWhen_CallerIsNotOwner() public {
        vm.expectRevert();
        vm.prank(address(0));
        demark.setPlatformFee(0);
    }

    function test_SuccessWhen_CallerIsOwner() public {
        vm.prank(demark.owner());
        demark.setPlatformFee(0);
        assertEq(0, demark.platformFee());
    }

    function testFail_cancelJobAsNonProposer() public {
        vm.prank(address(0));
        demark.cancelJob(0);
    }

}
