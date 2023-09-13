// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {Ownable} from "./Ownable.sol";
import {IDeMark} from "./IDeMark.sol";
import {MarketBuyable} from "./MarketBuyable.sol";

/**
    DeMark is a protocol designed to facilitate the sale of blockchain-based
    application software. Proposers will list jobs they need completed, sending 
    the amount to be paid upfront. Completors will complete the job and compete to 
    be selected by the Proposer. If selected, the completor will receive the payout
    associated with the job minus a platform fee.
 */
contract DeMark is Ownable, IDeMark {
    uint256 public platformFee;
    uint256 public accumulatedFees;
    MarketBuyable public solution;

    Job[] public jobs;
    struct Submission {
        address submitter;
        address solutionContract;
    }

    // The submissions mapping is used to quickly find all submissions related to a specific jobId.
    // It maps from a jobId to an array of Submission structs.
    mapping(uint256 => Submission[]) public submissions;
    constructor(uint256 _platformFee) Ownable(_msgSender()) {
        platformFee = _platformFee;
    }

    modifier onlyProposer(uint256 jobId) {
        if(_msgSender() != jobs[jobId].proposer) {
            revert NotProposer();
        }
        _;
    }

    modifier onlyCompletor(uint256 jobId) {
        if(_msgSender() != jobs[jobId].completedBy) {
            revert NotCompletor();
        }
        _;
    }

    function setPlatformFee(uint256 _platformFee) external payable onlyOwner {
        platformFee = _platformFee;
    }

    function isContract(address _addr) public view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function proposeJob(string memory _jobDescription) external payable override {
        if(msg.value < 100) {
            revert PayoutLowerThan100Wei();
        }
        jobs.push(Job(_msgSender(), msg.value, _jobDescription, address(0), block.timestamp, 0, 0, 0));

        emit JobCreated(_msgSender(), msg.value, _jobDescription);
    }

    function cancelJob(uint256 jobId) external payable onlyProposer(jobId) override {
        if(jobs[jobId].completedBy != address(0)) {
            revert AlreadyCompletedOrCanceled();
        }
        jobs[jobId].completedBy = jobs[jobId].proposer; // Protects from reentrancy

        (bool success,) = jobs[jobId].proposer.call{value: jobs[jobId].payout}("");
        require(success, "Transfer Failure");

        emit JobCanceled(jobId);
    }

    function submitSolution(uint256 jobId, address _solutionContract) external payable override {
        if(_msgSender() == jobs[jobId].proposer) {
            revert ProposerCannotSubmit();
        }
        if(!isContract(_solutionContract)){
            revert NotContract();
        }

        solution = MarketBuyable(_solutionContract);

        if(!solution.isApproved(address(this))) {
            revert ContractNotBuyable();
        }
        if(solution.owner() != _msgSender()) {
            revert SenderNotContractOwner();
        }

        submissions[jobId].push(Submission(_msgSender(), _solutionContract));
        emit ContractSubmitted(jobId, _msgSender(), _solutionContract);
    }

    function markComplete(uint256 jobId, uint256 submissionId) external payable override {
        if(jobs[jobId].completedBy != address(0)) {
            revert AlreadyCompletedOrCanceled();
        }
        jobs[jobId].completedBy = submissions[jobId][submissionId].submitter; // Protects from reentrancy

        if(submissions[jobId][submissionId].submitter == address(0)) {
            revert NotASubmission();
        }
        /**
            @note Will need to control for smart contracts that have malicious code pretending
            to be MarketBuyalbe.sol in order to receive a payout without transferring
            ownership of the contract. Similar to DEXs, no one can prevent malicious interactions
            with this contract, but the frontend can detect and blacklist malicious contracts.
        */
        solution = MarketBuyable(submissions[jobId][submissionId].solutionContract);
        solution.marketTransferOwnership(jobs[jobId].proposer);

        require(solution.owner() == jobs[jobId].proposer, "Ownership transfer unsuccessful");

        jobs[jobId].completedAt = block.timestamp;
        /**
            @dev fee calculation gets 1% of payout and multiplies that by platformFee
                ex. if payout is 1 eth and platform fee is 10%, calculation would be
                    1eth / 100 * 10 => 0.01eth * 10 => 0.1eth
                    real values are in wei to avoid losing decimals
         */
        uint256 fee = (jobs[jobId].payout / 100) * platformFee;
        uint256 finalPayout = jobs[jobId].payout - fee;
        accumulatedFees += fee;

        (bool success,) = submissions[jobId][submissionId].submitter.call{value: finalPayout}("");
        require(success, "payout failed");

        emit JobCompleted(submissions[jobId][submissionId].submitter, jobId);
    }

    function withdrawPlatformFees() external payable onlyOwner {
        if(accumulatedFees == 0) {
            revert();
        }
        uint256 val = accumulatedFees;
        accumulatedFees = 0; // Protects from reentrancy

        (bool success,) = payable(owner()).call{value: val}("");
        require(success, "Transfer failure");
    }
    
    function getIncompleteJobs() public view returns (Job[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < jobs.length; i++) {
            if (jobs[i].completedAt == 0) {
                count++;
            }
        }

        Job[] memory incompleteJobs = new Job[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < jobs.length; i++) {
            if (jobs[i].completedAt == 0) {
                incompleteJobs[index] = jobs[i];
                index++;
            }
        }

        return incompleteJobs;
    }

    function getSubmissionsForJob(uint256 jobId) public view returns (Submission[] memory) {
        return submissions[jobId];
    }

}