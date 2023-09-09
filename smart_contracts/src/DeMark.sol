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

    Job[] public jobs;

    /**
        stores ratings on a 1-5 scale for proposers and laborers
        ratings[userAddress]['proposer'] => the array of ratings of userAddress as a proposer
        ratings[userAddress]['completor'] => the array of ratings of userAddress as a completor
     */
    struct Rating {
        uint256 totalRating;
        uint256 ratingCount;
    }

    mapping(address => mapping(string => Rating)) public ratings;
    mapping(address => mapping(uint256 => address)) public submissions;
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
        if(submissions[_msgSender()][jobId] != address(0)) {
            revert AlreadySubmitted();
        }
        if(!isContract(_solutionContract)){
            revert NotContract();
        }
        
        MarketBuyable solution = MarketBuyable(_solutionContract);

        if(solution.marketplaceContract() != address(this)) {
            revert ContractNotBuyable();
        }
        if(solution.owner() != _msgSender()) {
            revert SenderNotContractOwner();
        }

        submissions[_msgSender()][jobId] = _solutionContract;
    }

    function markComplete(uint256 jobId, address _completedBy) external payable override {
        if(jobs[jobId].completedBy != address(0)) {
            revert AlreadyCompletedOrCanceled();
        }
        jobs[jobId].completedBy = _completedBy; // Protects from reentrancy

        if(submissions[_completedBy][jobId] == address(0)) {
            revert NotASubmission();
        }
        /**
            @note Will need to control for smart contracts that have malicious code pretending
            to be MarketBuyalbe.sol in order to receive a payout without transferring
            ownership of the contract. Similar to DEXs, no one can prevent malicious interactions
            with this contract, but the frontend can detect and blacklist malicious contracts.
        */
        MarketBuyable solution = MarketBuyable(submissions[_completedBy][jobId]);
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

        (bool success,) = _completedBy.call{value: finalPayout}("");
        require(success, "payout failed");

        emit JobCompleted(_completedBy, jobId);
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

    function rateCompletor(uint256 jobId, uint8 rating) external payable override onlyProposer(jobId) {
        if(jobs[jobId].completorRating != 0) {
            revert AlreadyRated();
        }

        if(rating < 1 || rating > 5) {
            revert MustBeBetweenOneAndFiveInclusive();
        }
        ratings[jobs[jobId].completedBy]['completor'].totalRating += rating;
        ratings[jobs[jobId].completedBy]['completor'].ratingCount += 1;
    }

    function rateProposer(uint256 jobId, uint8 rating) external payable override onlyCompletor(jobId) {
        if(jobs[jobId].proposerRating != 0) {
            revert AlreadyRated();
        }

        if(rating < 1 || rating > 5) {
            revert MustBeBetweenOneAndFiveInclusive();
        }
        ratings[jobs[jobId].proposer]['proposer'].totalRating += rating;
        ratings[jobs[jobId].proposer]['proposer'].ratingCount += 1;
    }

    function getAverageRating(string memory proposerOrCompletor, address user) public view override returns(uint256) {
        uint256 averageRating;
        uint256 totalRatings = ratings[user][proposerOrCompletor].totalRating;
        uint256 numOfRatings = ratings[user][proposerOrCompletor].ratingCount;

        if(numOfRatings == 0) {
            return averageRating; // returns 0
        }

        /**
            @note averageRating will be some 3 digit number
            ex. if a user's ratings are [1, 5, 2, 3] the calculation will be
                11 * 100 / 4 = 275 => corresponds to a 2.75/5 average rating
        */ 
        averageRating = (totalRatings * 100) / numOfRatings;

        return averageRating;
    }
}