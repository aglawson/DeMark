// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Ownable} from "./Ownable.sol";
import {IDeMark} from "./IDeMark.sol";
contract DeMark is Ownable, IDeMark {
    uint256 public platformFee;
    uint256 public accumulatedFees;

    Job[] public jobs;

    /**
        stores ratings on a 1-5 scale for proposers and laborers
        ratings[userAddress]['proposer'] => the array of ratings of userAddress as a proposer
        ratings[userAddress]['completor'] => the array of ratings of userAddress as a completor
     */
    mapping(address => mapping(string => uint8[])) public ratings;

    constructor(uint256 _platformFee) Ownable(_msgSender()) {
        require(_platformFee > 0, "Platform fee must be > 0");
        
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

    function proposeJob(string memory _jobDescription) external payable override {
        jobs.push(Job(_msgSender(), msg.value, _jobDescription, address(0), block.timestamp, 0, 0, 0));

        emit JobCreated(_msgSender(), msg.value, _jobDescription);
    }

    function markComplete(uint256 jobId, address _completedBy, uint8 rating) external payable override {
        if(jobs[jobId].completedBy == address(0)) {
            revert AlreadyCompleted();
        }
        jobs[jobId].completedBy = _completedBy;

        if(rating < 1 || rating > 5) {
            revert MustBeBetweenOneAndFiveInclusive();
        }
        jobs[jobId].completorRating = rating;

        jobs[jobId].completedAt = block.timestamp;

        uint256 fee = (jobs[jobId].payout / 100) * platformFee;
        uint256 finalPayout = jobs[jobId].payout - fee;

        accumulatedFees += fee;

        (bool success,) = _completedBy.call{value: finalPayout}("");
        require(success, "payout failed");

        emit JobCompleted(_completedBy, jobId);
    }

    function rateProposer(uint256 jobId, uint8 rating) external payable override onlyCompletor(jobId) {
        if(jobs[jobId].proposerRating != 0) {
            revert AlreadyRated();
        }
        
        if(rating < 1 || rating > 5) {
            revert MustBeBetweenOneAndFiveInclusive();
        }
        ratings[jobs[jobId].proposer]['proposer'].push(rating);
    }


}
