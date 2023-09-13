// SPDX-License-Identifier: MIT

/**
    @note NEED TO REFACTOR FOR DEMARK INTEROPERABILITY
 */

pragma solidity ^0.8.0;

import "./Ownable.sol";

contract MarketBuyable is Ownable {
    mapping(address => bool) public approvedMarketplaces;
    address[] public approvals;

    event listed(address seller, address contractAddress, uint256 price);
    event bought(address seller, address buyer, address contractAddress, uint256 price);
    event unlisted(address seller, address contractAddress);

    constructor() Ownable(_msgSender()) {}

    modifier marketplaceOnly {
        if(!approvedMarketplaces[msg.sender]) {
            revert("caller not approved");
        }
        _;
    }

    function approveMarketplace(address _marketplace) public onlyOwner {
        if(approvedMarketplaces[_marketplace])
            revert("already approved");

        approvals.push(_marketplace);
        approvedMarketplaces[_marketplace] = true;
    }

    function revokeMarketplace(address _marketplace) external onlyOwner {
        if(!approvedMarketplaces[_marketplace])
            revert("already not approved");

        approvedMarketplaces[_marketplace] = false;
        delete(approvals[indexOf(_marketplace)]);
    }

    function _clearApprovals() internal {
        for(uint i = 0; i < approvals.length; i++) {
            approvedMarketplaces[approvals[i]] = false;
            delete(approvals[i]);
        }
    }

    function indexOf(address _marketplace) public view returns(uint256){
        for(uint i = 0; i < approvals.length; i++) {
            if(approvals[i] == _marketplace)
                return i;
        }

        return 0;
    }

    function isApproved(address _marketplace) public view returns(bool) {
        return approvedMarketplaces[_marketplace];
    }

    function marketTransferOwnership(address _newOwner) external marketplaceOnly {
        _transferOwnership(_newOwner);
    }
}