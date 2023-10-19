// SPDX-License-Identifier: No License
pragma solidity ^0.8.19;
import "./DeMark.sol";
import "./AccessControl.sol";

/**
    @dev Auditors is a contract where auditors can either flag a contract for flawed or 
         malicious code, or vouch for its quality and completeness. Auditors will be rewarded
         for being correct (which is confirmed if there is no conflict within x amount of time or
         if a conflict is resolved in favor of the contract submitter) and punished for being wrong.
         This punishment and reward logic will depend largely on the ConflictResolution contract.
 */

contract Audits is AccessControl{
    bytes32 public constant AUDITOR = keccak256("AUDITOR");

    event NewAuditor(address indexed auditor, uint256 indexed initialStake);
    event AddStake(address indexed auditor, uint256 indexed deposit, uint256 indexed newTotalStake);
    event AuditSubmitted(address indexed auditor, bool passed, uint256 weight);

    struct Auditor {
        address wallet;
        uint256 stake;
        uint256 totalWeight;
        uint256 allocatedWeight;
        uint256 createdAt;
    }
    mapping(address => Auditor) public auditors;

    struct Audit {
        address _contract;
        address auditor;
        bool passed;
        uint256 weight;
    }
    mapping(address => Audit) public audits;

    constructor() {

    }

    function becomeAuditor() external payable {
        require(msg.value > 0, "Value must be > 0");
        require(!hasRole(AUDITOR, _msgSender()), "Already auditor");

        auditors[_msgSender()] = Auditor(_msgSender(), msg.value, 1, 0, block.timestamp);
        _grantRole(AUDITOR, _msgSender());

        emit NewAuditor(_msgSender(), msg.value);
    }

    function addToStake() external onlyRole(AUDITOR) payable {
        require(msg.value > 0, "Value must be > 0");

        auditors[_msgSender()].stake += msg.value;

        emit AddStake(_msgSender(), msg.value, auditors[_msgSender()].stake);
    }

    function submitAudit(address _contract, bool passed, uint256 weight) external onlyRole(AUDITOR) {
        // add logic to record answer to be checked later in ConflictResolution
        require(
            auditors[_msgSender()].allocatedWeight + weight <= auditors[_msgSender()].totalWeight, 
            "Auditor has insufficient weight"
        );

        auditors[_msgSender()].allocatedWeight += weight;
        audits[_msgSender()] = Audit(_contract, _msgSender(), passed, weight);

        emit AuditSubmitted(_msgSender(), passed, weight);
    }

}