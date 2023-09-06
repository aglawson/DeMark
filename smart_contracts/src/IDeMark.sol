// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface IDeMark {

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

    event JobCreated(address proposer, uint256 payout, string jobDescription);
    event JobCompleted(address completedBy, uint256 jobId);
    event JobCanceled(uint256 jobId);
    event ContractSubmitted(uint256 jobId, address submitter, address submissionContract);

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

    function cancelJob(uint256 jobId) external payable;

    function submitSolution(uint256 jobId, address _solutionContract) external payable;

    /**
        @dev emits a 'JobCompleted' event
    */
    function markComplete(uint256 jobId, address _completedBy) external payable;

    /**
        @dev allows job proposer to rate their experience with job completor
     */
    function rateCompletor(uint256 jobId, uint8 rating) external payable;
    /**
        @dev allows job completer to rate their experience with the job proposer
     */
    function rateProposer(uint256 jobId, uint8 rating) external payable;

    /**
        @dev calculates average rating of 'user' for their role as 'proposerOrCompletor'
     */
    function getAverageRating(string memory proposerOrCompletor, address user) external view returns(uint256);
}