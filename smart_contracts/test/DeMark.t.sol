// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "../lib/forge-std/src/Test.sol";
import {DeMark} from "../src/DeMark.sol";
import {MarketBuyable} from "../src/MarketBuyable.sol";

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

contract ContractForSale is MarketBuyable{
    constructor(address marketplace) MarketBuyable(marketplace) {}
}

contract CounterTest is Test {
    DeMark public demark;
    ContractForSale public cfs;

    function setUp() public {
        demark = new DeMark(10);
        cfs = new ContractForSale(address(demark));
    }

    function test_CFSInitializedCorrectly() public {
        assertEq(cfs.marketplaceContract(), address(demark));
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

    function test_RevertCancelJobWhen_CallerIsNotProposer() public {
        vm.expectRevert();
        vm.prank(address(0));
        demark.cancelJob(0);
    }

}
