// SPDX-License-Identifier: MIT

/**
    @note NEED TO REFACTOR FOR DEMARK INTEROPERABILITY
 */

pragma solidity ^0.8.0;

import "./Ownable.sol";

contract MarketBuyable is Ownable {
    address public marketplaceContract;

    error MarketplaceOnly();

    event listed(address seller, address contractAddress, uint256 price);
    event bought(address seller, address buyer, address contractAddress, uint256 price);
    event unlisted(address seller, address contractAddress);

    constructor(address _marketplace) Ownable(_msgSender()) {
        marketplaceContract = _marketplace;
    }

    modifier marketplaceOnly {
        if(msg.sender != marketplaceContract) {
            revert MarketplaceOnly();
        }
        _;
    }

    function setMarketplaceAddress(address _marketplace) public onlyOwner {
        marketplaceContract = _marketplace;
    }

    function revokeMarketplace() external onlyOwner {
        setMarketplaceAddress(address(0));
    }

    function marketTransferOwnership(address _newOwner) external marketplaceOnly {
        _transferOwnership(_newOwner);
    }
}