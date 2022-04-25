# Tipshot V1

Smart contracts that allow the flexible sale and purchase of sport prediction tips on the polygon network.

[![Tests pass](https://github.com/tipshot-net/smart-contract/actions/workflows/main.yml/badge.svg)](https://github.com/tipshot-net/smart-contract/actions/workflows/main.yml)

## Tipshot

This repository contains the smart contracts source code for the Tipshot marketplace Protocol and Miners NFT contract. The repository uses Hardhat as development enviroment for compilation, testing and deployment tasks.

## How does Tipshot work?

Tipshot is a decentralized sport tips marketplace that allows tipsters & bettors to interact and transact on a global, permission-less, censorship-resistant and self-executing platform. Betting tips can be bought and sold via the protocol.

To enable validation of state transitions during consensus, blockchain data is public. Existing smart contract systems thus lack confidentiality or privacy: They cannot safely store or compute sensitive data (e.g. sport tips, financial transactions).

To address this issue of privacy while maintaining a decentralized structure. Tips information is encrypted by a private node, before they are deployed and stored on the smart contract storage

![How tips are stored](https://res.cloudinary.com/iberdrola/image/upload/v1650875877/tipshot/how_tips_are_stored.png)

Before tips can be listed on the platform, they must be validated by a delegated group of miners to ensure that the tips meets the required level of correctness and standards. Miners are required to lock up some value of token as stake. A miner's stake is used as a way to incentivise good validator behavior because malicious validation could lock up the miner's stake for a long period before release.

![How tips are validated](https://res.cloudinary.com/iberdrola/image/upload/v1650877674/tipshot/how_tips_are_validated.png)

To purchase published tips, users are required to submit a purchase key, (alongside the purchase fee, if any) the key is encrypted and stored as part of the purchase data in the smart contract, the key would be used to verify a purchase whenever wants to view the tip.

![How tips are purchased](https://res.cloudinary.com/iberdrola/image/upload/v1650894807/tipshot/how_tips_are_purchased.png)

After a successful purchase, the user can view the tip anytime without a need to send a transaction to the blockchain, the request is sent to the private node, the purchase is verified and the tips data is sent back as response

![unveiling purchased tip](https://res.cloudinary.com/iberdrola/image/upload/v1650887800/tipshot/unveiling_tip.png)

At the end of the tips events, the miners are expected to, once again decide the overall outcome of the tip.
The outcome is decided by the majority vote, if the outcome is WON, the miners take thier % commision from the total earned from the sale and the tipster takes the rest, on the other hand, if the outcome is LOST, all purchases for that tip are automatically refunded.

![transaction conclusion](https://res.cloudinary.com/iberdrola/image/upload/v1650888575/tipshot/how_the_transaction_is_concluded.png)

\*tipsters are allowed to publish paid tips only when they have a profitable recent history.

## Development

First clone this repository and enter the directory.

Install dependencies:

```
$ npm install
```

## Testing

We use [Hardhat](https://hardhat.dev) and [hardhat-deploy](https://github.com/wighawag/hardhat-deploy)

To run integration tests:

```sh
$ npx hardhat test
```

To run coverage:

```sh
$ npx hardhat coverage
```

To deploy to Rinkeby:
create a .env file containing the required private keys(see .env.example) then run:

```sh
$ npx hardhat deploy-rinkeby
```

To verify the auction contract run:

```sh
$ yarn verify-auction [AUCTION-CONTRACT-ADDRESS]
```

A verified version of the Tipshot contract on the polygon mumbai test network is available at address:
0x0000000000000000000000000000000000000000
https://rinkeby.etherscan.io/address/0x0000000000000000000000000000000000000000#code

A verified version of the Miner NFT contract on the polygon mumbai test network is available at address: 0x0000000000000000000000000000000000000000
https://rinkeby.etherscan.io/address/0x0000000000000000000000000000000000000000#code

## Discussion

For questions about the protocol, send us an email [team@tipshot.net](team@tipshot.net).

\_© Copyright 2022, Tipshot Team
