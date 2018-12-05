pragma solidity ^0.4.25;

import "openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol";
import "openzeppelin-solidity/contracts/token/ERC20/CappedToken.sol";


contract LockedToken is CappedToken {
    bool public transferActivated = false;

    event TransferActivatedEvent();

    constructor(uint256 _cap) public CappedToken(_cap) {
    }

    /**
     * @dev Admin function.
     * @dev Activates the token transfer. This action cannot be undone. 
     * @dev This function should be called after the ICO. 
     * @return True if ok. 
     */
    function activateTransfer() 
        public 
        onlyOwner
        returns (bool) 
    {
        require(transferActivated == false, "Already activated");

        transferActivated = true;

        emit TransferActivatedEvent();
        return true;
    }

    /**
     * @dev Transfer token for a specified address.
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(
        address _to, 
        uint256 _value
    ) 
        public 
        returns (bool) 
    {
        require(transferActivated, "Transfer is not activated");
        require(_to != address(this), "Invalid _to address");

        return super.transfer(_to, _value);
    }

    /**
     * @dev Transfer tokens from one address to another.
     * @param _from The address which you want to send tokens from.
     * @param _to The address which you want to transfer to.
     * @param _value The amount of tokens to be transferred.
     */
    function transferFrom(
        address _from, 
        address _to, 
        uint256 _value
    ) 
        public 
        returns (bool) 
    {
        require(transferActivated, "TransferFrom is not activated");
        require(_to != address(this), "Invalid _to address");

        return super.transferFrom(_from, _to, _value);
    }
}