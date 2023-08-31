// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface IDeMark {

    error AlreadyCompleted();
    error NotProposer();
    error NotCompletor();
    error MustBeBetweenOneAndFiveInclusive();
    error AlreadyRated();

    event JobCreated(address proposer, uint256 payout, string jobDescription);
    event JobCompleted(address completedBy, uint256 jobId);
    struct Job {
        address proposer;
        uint256 payout;
        string jobDescription;
        address completedBy;
        uint256 createdAt;
        uint256 completedAt;
        uint8 proposerRating;
        uint8 completorRating;
    }

    /**
        @dev emits a 'JobCreated' event
     */
    function proposeJob(string memory _jobDescription) external payable;

    /**
        @dev emits a 'JobCompleted' event
    */
    function markComplete(uint256 jobId, address _completedBy, uint8 rating) external payable;

    /**
        @dev allows job completer to rate their experience with the job proposer
     */
    function rateProposer(uint256 jobId, uint8 rating) external payable;

    /**
        @dev calculates average rating of 'user' for their role as 'proposerOrCompletor'
     */
    function getAverageRating(string memory proposerOrCompletor, address user) external view returns(uint256);
}