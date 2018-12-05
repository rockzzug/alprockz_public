pragma solidity ^0.4.25;

import "./VestingPrivateSale.sol";
import "./VestingTreasury.sol";
import "./LockedToken.sol";
import "openzeppelin-solidity/contracts/AddressUtils.sol";


/**
 * @title The Alprockz ERC20 Token
 */
contract AlprockzToken is LockedToken {
    
    string public constant name = "AlpRockz";
    string public constant symbol = "APZ";
    uint8 public constant decimals = 18;
    VestingPrivateSale public vestingPrivateSale;
    VestingTreasury public vestingTreasury;

    constructor() public LockedToken(175 * 1000000 * (10 ** uint256(decimals))) {
    }

    /**
     * @dev Admin function.
     * @dev Inits the VestingPrivateSale functionality. 
     * @dev Precondition: VestingPrivateSale smart contract must be deployed!
     * @param _vestingContractAddr The address of the vesting contract for the function 'mintPrivateSale(...)'.
     * @return True if everything is ok.
     */
    function initMintVestingPrivateSale(
        address _vestingContractAddr
    ) 
        external
        onlyOwner
        returns (bool) 
    {
        require(address(vestingPrivateSale) == address(0x0), "Already initialized");
        require(address(this) != _vestingContractAddr, "Invalid address");
        require(AddressUtils.isContract(_vestingContractAddr), "Address is not a smart contract");
        
        vestingPrivateSale = VestingPrivateSale(_vestingContractAddr);
        require(address(this) == address(vestingPrivateSale.erc20Contract()), "Vesting link address not match");
        
        return true;
    }

    /**
     * @dev Admin function.
     * @dev Inits the VestingTreasury functionality. 
     * @dev Precondition: VestingTreasury smart contract must be deployed!
     * @param _vestingContractAddr The address of the vesting contract for the function 'mintTreasury(...)'.
     * @return True if everything is ok.
     */
    function initMintVestingTreasury(
        address _vestingContractAddr
    ) 
        external
        onlyOwner
        returns (bool) 
    {
        require(address(vestingTreasury) == address(0x0), "Already initialized");
        require(address(this) != _vestingContractAddr, "Invalid address");
        require(AddressUtils.isContract(_vestingContractAddr), "Address is not a smart contract");
        
        vestingTreasury = VestingTreasury(_vestingContractAddr);
        require(address(this) == address(vestingTreasury.erc20Contract()), "Vesting link address not match");
        
        return true;
    }

    /**
     * @dev Admin function.
     * @dev Bulk mint function to save gas. 
     * @dev both arrays requires to have the same length.
     * @param _recipients List of recipients.
     * @param _tokens List of tokens to assign to the recipients.
     */
    function mintArray(
        address[] _recipients, 
        uint256[] _tokens
    ) 
        external
        onlyOwner 
        returns (bool) 
    {
        require(_recipients.length == _tokens.length, "Array length not match");
        require(_recipients.length <= 40, "Too many recipients");

        for (uint256 i = 0; i < _recipients.length; i++) {
            require(super.mint(_recipients[i], _tokens[i]), "Mint failed");
        }

        return true;
    }

    /**
     * @dev Admin function.
     * @dev Bulk mintPrivateSale function to save gas. 
     * @dev both arrays are required to have the same length.
     * @dev Vesting: 25% directly available, 25% after 6, 25% after 12 and 25% after 18 months. 
     * @param _recipients List of recipients.
     * @param _tokens List of tokens to assign to the recipients.
     */
    function mintPrivateSale(
        address[] _recipients, 
        uint256[] _tokens
    ) 
        external 
        onlyOwner
        returns (bool) 
    {
        require(address(vestingPrivateSale) != address(0x0), "Init required");
        require(_recipients.length == _tokens.length, "Array length not match");
        require(_recipients.length <= 10, "Too many recipients");


        for (uint256 i = 0; i < _recipients.length; i++) {

            address recipient = _recipients[i];
            uint256 token = _tokens[i];

            uint256 first;
            uint256 second; 
            uint256 third; 
            uint256 fourth;
            (first, second, third, fourth) = splitToFour(token);

            require(super.mint(recipient, first), "Mint failed");

            uint256 totalVested = second + third + fourth;
            require(super.mint(address(vestingPrivateSale), totalVested), "Mint failed");
            require(vestingPrivateSale.addVested(recipient, second, third, fourth), "Vesting failed");
        }

        return true;
    }

    /**
     * @dev Admin function.
     * @dev Bulk mintTreasury function to save gas. 
     * @dev both arrays are required to have the same length.
     * @dev Vesting: Tokens are locked for 6 months. After that the tokens are released in a linear way.
     * @param _recipients List of recipients.
     * @param _tokens List of tokens to assign to the recipients.
     */
    function mintTreasury(
        address[] _recipients, 
        uint256[] _tokens
    ) 
        external 
        onlyOwner
        returns (bool) 
    {
        require(address(vestingTreasury) != address(0x0), "Init required");
        require(_recipients.length == _tokens.length, "Array length not match");
        require(_recipients.length <= 10, "Too many recipients");

        for (uint256 i = 0; i < _recipients.length; i++) {

            address recipient = _recipients[i];
            uint256 token = _tokens[i];

            require(super.mint(address(vestingTreasury), token), "Mint failed");
            require(vestingTreasury.addVested(recipient, token), "Vesting failed");
        }

        return true;
    }

    function splitToFour(
        uint256 _amount
    ) 
        private 
        pure 
        returns (
            uint256 first, 
            uint256 second, 
            uint256 third, 
            uint256 fourth
        ) 
    {
        require(_amount >= 4, "Minimum amount");

        uint256 rest = _amount % 4;

        uint256 quarter = (_amount - rest) / 4;

        first = quarter + rest;
        second = quarter;
        third = quarter;
        fourth = quarter;
    }
}