pragma solidity ^0.4.25;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/AddressUtils.sol";


/**
 * Treasury vesting smart contract. Vesting period is over 36 months.
 * Tokens are locked for 6 months. After that releasing the tokens over 30 months with a linear function.
 */
contract VestingTreasury {

    using SafeMath for uint256;

    uint256 constant public sixMonths = 182 days;  
    uint256 constant public thirtyMonths = 912 days;  

    ERC20Basic public erc20Contract;

    struct Locking {
        uint256 startDate;      // date when the release process of the vesting will start. 
        uint256 initialized;    // initialized amount of tokens
        uint256 released;       // already released tokens
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
     * @param _value The amount of tokens to protect.
     * @return True if accepted.
     */
    function addVested(
        address _tokenHolder, 
        uint256 _value
    ) 
        public 
        returns (bool) 
    {
        require(msg.sender == address(erc20Contract), "ERC20 contract required");
        require(lockingMap[_tokenHolder].startDate == 0, "Address is already vested");

        lockingMap[_tokenHolder].startDate = block.timestamp + sixMonths;
        lockingMap[_tokenHolder].initialized = _value;
        lockingMap[_tokenHolder].released = 0;

        return true;
    }

    /**
     * @dev Calculates the amount of the total currently vested and available tokens.
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
        return lockingMap[_tokenHolder].initialized.sub(lockingMap[_tokenHolder].released);
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
        
        if (block.timestamp <= startDate) {
            return 0;
        }

        uint256 tmpAvailableTokens = 0;
        if (block.timestamp >= startDate + thirtyMonths) {
            tmpAvailableTokens = lockingMap[_tokenHolder].initialized;
        } else {
            uint256 timeDiff = block.timestamp - startDate;
            uint256 totalBalance = lockingMap[_tokenHolder].initialized;

            tmpAvailableTokens = totalBalance.mul(timeDiff).div(thirtyMonths);
        }

        uint256 availableTokens = tmpAvailableTokens.sub(lockingMap[_tokenHolder].released);
        require(availableTokens <= lockingMap[_tokenHolder].initialized, "Max value exceeded");

        return availableTokens;
    }

    /**
     * @dev Releases unlocked tokens of the transaction sender. 
     * @dev This function will transfer unlocked tokens to the owner.
     * @return The total amount of released tokens.
     */
    function releaseTokens() 
        public 
        returns (uint256) 
    {
        require(lockingMap[msg.sender].startDate != 0, "Sender is not a vested address");

        uint256 tokens = availableBalanceOf(msg.sender);

        lockingMap[msg.sender].released = lockingMap[msg.sender].released.add(tokens);
        require(lockingMap[msg.sender].released <= lockingMap[msg.sender].initialized, "Max value exceeded");

        require(erc20Contract.transfer(msg.sender, tokens), "Transfer failed");
        emit ReleaseVestingEvent(msg.sender, tokens);

        return tokens;
    }
}