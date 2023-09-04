// SPDX-License-Identifier: MIT

/**
    @note NEED TO REFACTOR FOR DEMARK INTEROPERABILITY
 */

pragma solidity ^0.8.0;

import "./Ownable.sol";

abstract contract Buyable is Ownable {
    address private _originalOwner;

    bool public isBuyable;

    uint256 public priceOfContract;
    uint256 public feePct;

    event listed(address seller, address contractAddress, uint256 price);
    event bought(address seller, address buyer, address contractAddress, uint256 price);
    event unlisted(address seller, address contractAddress);

    /**
     * @dev Initializes the contract setting the deployer as the original owner.
     */
    constructor() {
        _originalOwner = _msgSender();
    }

    modifier originalOwner {
        require(_originalOwner == _msgSender(), "Buyable: Caller is not original owner");
        _;
    }

    /**
     * @dev Makes ownership of contract purchasable 
     * price is in Wei => 1 * 10^-18 ETH
     * price must be higher than 100 Wei to prevent percentage calculation errors
     */
    function sellContract(uint256 _priceOfContract) public onlyOwner {
        require(_priceOfContract >= 100, "Buyable: Proposed price must be higher than 100 Wei");
        isBuyable = true;
        priceOfContract = _priceOfContract;

        emit listed(_msgSender(), address(this), _priceOfContract);
    }

    /**
     * @dev Ends sale of ownership, makes contract not purchasable
     */
    function endSale() public onlyOwner {
        isBuyable = false;

        emit unlisted(_msgSender(), address(this));
    }

    /**
     * @dev Results in transfer of ownership, if conditions are met 
     * will always transfer a royalty to _originalOwner
     */
    function buyContract() public payable {
        require(isBuyable, "Buyable: Contract not for sale");
        require(msg.value == priceOfContract, "Buyable: invalid amount sent");

        address oldOwner = owner();

        isBuyable = false;
        priceOfContract = 0;

        uint256 fee = (msg.value / 100) * feePct;

        (bool success,) = owner().call{value: msg.value - fee}("");
        require(success, 'Transfer fail');

        (bool success2,) = _originalOwner.call{value: fee}("");
        require(success2, 'Transfer fail');

        _transferOwnership(_msgSender());

        emit bought(oldOwner, _msgSender(), address(this), msg.value);
    }

    /**
     * @dev Sets percentage fee to charge for all future contract sales
     * fee goes to _originalOwner
     * must be an integer from 0 to 10 
     */
    function setFee(uint256 _feepct) public originalOwner {
        require(_feepct <= 10, "Buyable: Fee percentage exceeds upper limit");
        feePct = _feepct;
    }

    function buyable() external view returns(bool) {
        return isBuyable;
    }
}