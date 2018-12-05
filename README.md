# Alprockz – APZ Token

AlpRockz Ltd, in order to develop the Rockz project, issues a utility token, called APZ.

Further documentation

- Developer documentation: [README-DEV.md](./docs/README-DEV.md)
- Deployment documentation: [DEPLOYMENT.md](./docs/DEPLOYMENT.md)
- Changelog: [changelog.md](./docs/changelog.md)

## Overview

## Properties

- Token Type: ERC20
- Symbol: APZ
- Name: AlpRockz
- Decimals: 18
- Max Tokens: 175 Million APZ. (Or less)

## The Contract and Functionalities

The `AlprockzToken.sol` provides several features.

### ERC20

Implements the standard ERC20 interface. See [page](https://theethereum.wiki/w/index.php/ERC20_Token_Standard).

## Alprockz Token Contract

Gas Usage estimations:
![Class diagram](./docs/alprockz-minting-gas-usage.jpg)

### Minting

Minting expects an array of recipients and an array of tokens. So it's possible to mint for multiple recipients in one transaction. Used to save Gas.

`function mintArray(address[] recipients, uint256[] tokens)`

### Mint Private Sale

This minting function is required for minting to investors who invested during the private sale. These tokens are subject to vesting. Vesting is split up into four buckets:

Bucket | Percentage | Lock time
--- | --- | ---
Bucket 1 | 25% | Directly after minting available
Bucket 2 | 25% | Available after 6 month
Bucket 3 | 25% | Available after 12 month
Bucket 4 | 25% | Available after 18 month

`function mintVested(address[] _recipients, uint256[] _tokens)`

**Limitations:**

- One address (aka recipient) can only handle exactly one vesting!
- Minimum amount of tokens are 4.

### Mint Treasury

This minting function is required for the treasury requirement. This functionality is for Alprockz.
Details: [Excel](./docs/treasury-vesting.xlsx)

`function mintPrivateSale(address[] _recipients, uint256[] _tokens)`

**Limitations:**

- One address (aka recipient) can only handle exactly one vesting!
- Minimum amount of tokens are 4.

### Finalize minting

During the minting process 175 Million APZ can be minted. This is the absolute maximum of tokens. If not all tokens are sold during the ICO then only the sold tokens will be minted. When the minting process has finished and all tokens are assigned to the token holders / investors, then the contract owner can call `finishMinting()`. This will lock the minting process and no more tokens can be generated.

### activateTransfer

By default after the deployment the smart contract is "locked". So all tokens transfers are locked. Minting is activated. The function `activateTransfer()` allows the contract owner to enable the `transfer` and `transferFrom` functionality. This action can not be undone. The idea behind this is, that all tokens are locked until the ICO is over.

## Alprockz Private Sale Vesting Contract

### Release vested tokens

The vesting tokens are in supply and managed (locked) by a vesting contract. The token owners or the vesting contract owner are able to release funds after the vesting periods.

After a vesting period the vesting contract owner (Alprockz) is able to release funds for a specific address:

`function releaseTokens(address _tokenHolder) public returns (uint256)`

After the vesting period is over, the token owner is able to release his own funds:

`function releaseTokens() public returns (uint256)`

These functions will transfer the tokens to the right owner and afterwards the tokens will be immediately available in the token contract.

## Alprockz Treasury Vesting Contract

Same mechanics as the Private Sale Vesting Contract.

## Varia

- The contract does not allow Ether.
- The contract can not be destroyed.

### Transfer Ownership

The owner of the contract is able to transfer the ownership to an new owner.
The owner of the contract is allowed to mint. When the minting process ends (maximum amount of tokens minted), even the owner of the contract is prohibited from minting further tokens.

### init methods

Both smart contracts `AlprockzToken` and `Vesting` have an init method. This was introduced to simplify the code publish in etherscan.io. If a smart contract creates an other smart contract with constructur parameters it can get difficult to publish the source code in etherscan.io. On Rinkeby it was not possible to publish the source for the `Vesting` smart contract.