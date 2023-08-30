// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface IDeMark {

    error AlreadyCompleted();
    error NotProposer();

    event JobCreated(address proposer, uint256 payout, string jobDescription);
    event JobCompleted(address completedBy, uint256 jobId);
    struct Job {
        address proposer;
        uint256 payout;
        string jobDescription;
        address completedBy;
    }

    /**
        @dev emits a 'JobCreated' event
     */
    function proposeJob(string memory _jobDescription) external payable;

    /**
        @dev emits a 'JobCompleted' event
    */
    function markComplete(uint256 jobId, address _completedBy) external payable;
}