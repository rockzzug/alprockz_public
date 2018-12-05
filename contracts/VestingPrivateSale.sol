pragma solidity ^0.4.25;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/AddressUtils.sol";


/**
 * Vesting smart contract for the private sale. Vesting period is 18 months in total.
 * All 6 months 33% percent of the vested tokens will be released - step function.
 */
contract VestingPrivateSale is Ownable {

    uint256 constant public sixMonth = 182 days;  
    uint256 constant public twelveMonth = 365 days;  
    uint256 constant public eighteenMonth = sixMonth + twelveMonth;

    ERC20Basic public erc20Contract;

    struct Locking {
        uint256 bucket1;
        uint256 bucket2;
        uint256 bucket3;
        uint256 startDate;
    }

    mapping(address => Locking) public lockingMap;

    event ReleaseVestingEvent(address indexed to, uint256 value);

    /**
     * @dev Constructor. With the reference to the ERC20 contract
     */
    constructor(address _erc20) public {
        require(AddressUtils.isContract(_erc20), "Address is not a smart contract");

        erc20Contract = ERC20Basic(_erc20);
    }

    /**
     * @dev Adds vested tokens to this contract. ERC20 contract has assigned the tokens. 
     * @param _tokenHolder The token holder.
     * @param _bucket1 The first bucket. Will be available after 6 months.
     * @param _bucket2 The second bucket. Will be available after 12 months.
     * @param _bucket3 The third bucket. Will be available after 18 months.
     * @return True if accepted.
     */
    function addVested(
        address _tokenHolder, 
        uint256 _bucket1, 
        uint256 _bucket2, 
        uint256 _bucket3
    ) 
        public 
        returns (bool) 
    {
        require(msg.sender == address(erc20Contract), "ERC20 contract required");
        require(lockingMap[_tokenHolder].startDate == 0, "Address is already vested");

        lockingMap[_tokenHolder].startDate = block.timestamp;
        lockingMap[_tokenHolder].bucket1 = _bucket1;
        lockingMap[_tokenHolder].bucket2 = _bucket2;
        lockingMap[_tokenHolder].bucket3 = _bucket3;

        return true;
    }

    /**
     * @dev Calculates the amount of the total assigned tokens of a tokenholder.
     * @param _tokenHolder The address to query the balance of.
     * @return The total amount of owned tokens (vested + available). 
     */
    function balanceOf(
        address _tokenHolder
    ) 
        public 
        view 
        returns (uint256) 
    {
        return lockingMap[_tokenHolder].bucket1 + lockingMap[_tokenHolder].bucket2 + lockingMap[_tokenHolder].bucket3;
    }

    /**
     * @dev Calculates the amount of currently available (unlocked) tokens. This amount can be unlocked. 
     * @param _tokenHolder The address to query the balance of.
     * @return The total amount of owned and available tokens.
     */
    function availableBalanceOf(
        address _tokenHolder
    ) 
        public 
        view 
        returns (uint256) 
    {
        uint256 startDate = lockingMap[_tokenHolder].startDate;
        uint256 tokens = 0;
        
        if (startDate + sixMonth <= block.timestamp) {
            tokens = lockingMap[_tokenHolder].bucket1;
        }

        if (startDate + twelveMonth <= block.timestamp) {
            tokens = tokens + lockingMap[_tokenHolder].bucket2;
        }

        if (startDate + eighteenMonth <= block.timestamp) {
            tokens = tokens + lockingMap[_tokenHolder].bucket3;
        }

        return tokens;
    }

    /**
     * @dev Releases unlocked tokens of the transaction sender. 
     * @dev This function will transfer unlocked tokens to the owner.
     * @return The total amount of released tokens.
     */
    function releaseBuckets() 
        public 
        returns (uint256) 
    {
        return _releaseBuckets(msg.sender);
    }

    /**
     * @dev Admin function.
     * @dev Releases unlocked tokens of the _tokenHolder. 
     * @dev This function will transfer unlocked tokens to the _tokenHolder.
     * @param _tokenHolder Address of the token owner to release tokens.
     * @return The total amount of released tokens.
     */
    function releaseBuckets(
        address _tokenHolder
    ) 
        public 
        onlyOwner
        returns (uint256) 
    {
        return _releaseBuckets(_tokenHolder);
    }

    function _releaseBuckets(
        address _tokenHolder
    ) 
        private 
        returns (uint256) 
    {
        require(lockingMap[_tokenHolder].startDate != 0, "Is not a locked address");
        uint256 startDate = lockingMap[_tokenHolder].startDate;
        uint256 tokens = 0;
        
        if (startDate + sixMonth <= block.timestamp) {
            tokens = lockingMap[_tokenHolder].bucket1;
            lockingMap[_tokenHolder].bucket1 = 0;
        }

        if (startDate + twelveMonth <= block.timestamp) {
            tokens = tokens + lockingMap[_tokenHolder].bucket2;
            lockingMap[_tokenHolder].bucket2 = 0;
        }

        if (startDate + eighteenMonth <= block.timestamp) {
            tokens = tokens + lockingMap[_tokenHolder].bucket3;
            lockingMap[_tokenHolder].bucket3 = 0;
        }
        
        require(erc20Contract.transfer(_tokenHolder, tokens), "Transfer failed");
        emit ReleaseVestingEvent(_tokenHolder, tokens);

        return tokens;
    }
}