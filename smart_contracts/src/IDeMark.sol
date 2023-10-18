// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

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

    /**
        @dev cancels a job. Must be called by job proposer. 
        cancelled jobs can be identified by the fact that the 
        completedBy and proposer addresses will be identical.
     */
    function cancelJob(uint256 jobId) external payable;

    /**

     */
    function submitSolution(uint256 jobId, address _solutionContract) external payable;

    /**
        @dev emits a 'JobCompleted' event
    */
    function markComplete(uint256 jobId, uint256 submissionId)external payable;
}