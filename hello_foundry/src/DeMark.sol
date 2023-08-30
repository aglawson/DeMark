// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Ownable} from "./Ownable.sol";
import {IDeMark} from "./IDeMark.sol";
contract DeMark is Ownable, IDeMark {
    uint256 public platformFee;

    Job[] public jobs;
    constructor(uint256 _platformFee) {
        platformFee = _platformFee;
    }

    modifier onlyProposer(uint256 jobId) {
        if(_msgSender() != jobs[jobId].proposer) {
            revert NotProposer();
        }
        _;
    }

    function setPlatformFee(uint256 _platformFee) external payable onlyOwner {
        platformFee = _platformFee;
    }

    function proposeJob(string memory _jobDescription) external payable override {
        jobs.push(Job(_msgSender(), msg.value, _jobDescription, address(0)));

        emit JobCreated(_msgSender(), msg.value, _jobDescription);
    }

    function markComplete(uint256 jobId, address _completedBy) external payable override {
        if(jobs[jobId].completedBy == address(0)) {
            revert AlreadyCompleted();
        }
        jobs[jobId].completedBy = _completedBy;

        uint256 fee = jobs[jobId].payout / platformFee;
        uint256 finalPayout = jobs[jobId].payout - fee;

        (bool success,) = _completedBy.call{value: finalPayout}("");
    }
}
