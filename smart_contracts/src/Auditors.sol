// SPDX-License-Identifier: No License
pragma solidity 0.8.19;

/**
    @dev Auditors is a contract where auditors can either flag a contract for flawed or 
         malicious code, or vouch for its quality and completeness. Auditors will be rewarded
         for being correct (which is confirmed if there is no conflict within x amount of time or
         if a conflict is resolved in favor of the contract submitter) and punished for being wrong.
         This punishment and reward logic will depend largely on the ConflictResolution contract.
 */
contract Auditors {

}