# Foundry Smart Contract Lottery

This project contains a smart contract-based lottery system developed using the Foundry framework. It leverages Chainlink VRF V2.5 to ensure a provably fair and random selection of winners.

### Note on Chainlink VRF v2.5
[cite_start]V2.5 of Chainlink VRF uses a `uint256` for the subscription ID (`subId`) instead of a `uint64`.  [cite_start]This project includes a mock contract (`VRFCoordinatorV2_5Mock`) to facilitate development and testing with version 2.5. 

### Note on Foundry DevOps
[cite_start]This project utilizes version 0.1.0 of the `foundry-devops` package, which simplifies setup by not requiring the `ffi=true` flag in the configuration. 

---

## Quickstart Guide

### 1. Requirements
Before you begin, you need to have the following installed:
-   [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
    -   You'll know you've installed it correctly if you can run `git --version` and see a response like `git version x.x.x`.
-   [foundry](https://getfoundry.sh/)
    -   You'll know you've installed it correctly if you can run `forge --version` and see a response like `forge 0.2.0 (816e00b 2023-03-16T00:05:26.396218Z)`.

### 2. Installation & Setup
Clone the repository and install the dependencies:
```bash
git clone https://github.com/fricpto/foundry-smart-contract-lottery
cd foundry-smart-contract-lottery
forge install
forge build
```
### 3. Setup Environment Variables
You'll want to set your `SEPOLIA_RPC_URL` and `PRIVATE_KEY` as environment variables. You can add them to a `.env` file.

-   **`PRIVATE_KEY`**: The private key of your wallet.
    > **NOTE**: FOR DEVELOPMENT, PLEASE USE A KEY THAT DOESN'T HAVE ANY REAL FUNDS ASSOCIATED WITH IT.
-   **`SEPOLIA_RPC_URL`**: Your RPC URL for the Sepolia testnet, which you can get for free from a node provider like [Alchemy](https://www.alchemy.com/).
-   **`ETHERSCAN_API_KEY`** (Optional): Add your Etherscan API key if you want to verify your contract.

### 4. Get Testnet ETH and LINK
Head over to [faucets.chain.link](https://faucets.chain.link/) to get some testnet ETH and LINK for the Sepolia network.

### 5. Deploy the Contract
Run the following command to deploy the `Raffle` contract to Sepolia:
```bash
make deploy ARGS="--network sepolia"
```
This command will:

Deploy the `Raffle` contract.
Automatically set up a new Chainlink VRF Subscription if one isn't already specified in `script/HelperConfig.s.sol`.
Fund the subscription.
Add your newly deployed contract as a VRF consumer.

4. Register Chainlink Automation Upkeep
To have the lottery run automatically, you need to register it with Chainlink Automation.

Go to ([automation.chain.link](https://automation.chain.link/)) and register a new upkeep.
Select Custom logic as the trigger.
Enter the address of your deployed `Raffle` contract. Your UI will look something like this once completed:

5. Interact with the Contract
Once deployed, you can interact with the contract. For example, to enter the raffle using `cast`:
```bash
cast send <RAFFLE_CONTRACT_ADDRESS> "enterRaffle()" --value 0.01ether --private-key <YOUR_PRIVATE_KEY> --rpc-url $SEPOLIA_RPC_URL
```
(Note: Adjust the --value to match the entranceFee set in your contract).

Additional Commands
Create VRF Subscription Manually:

```bash
make createSubscription ARGS="--network sepolia"
```
Estimate Gas Usage:

```bash
forge snapshot
```
This will generate a `.gas-snapshot` file with gas cost estimates for the contract functions.

Format Code:

```bash
forge fmt
```
Project Structure
The project is organized into the following directories:

`src/`: Contains the core `Raffle.sol` smart contract.
`script/`: Includes deployment and interaction scripts.
`test/`: Contains unit, integration, and staging tests.
`lib/`: Houses dependencies like `forge-std`, `chainlink-contracts`, and `solmate`.

Core Contracts
`Raffle.sol`
This is the main contract for the lottery.

Description: It implements the `VRFConsumerBaseV2Plus` contract to interact with Chainlink's Verifiable Random Function (VRF). The contract allows users to enter a raffle, and after a specified interval, it uses Chainlink VRF to pick a random winner and transfer the prize pool to them.

State Variables:
`i_entranceFee`: The cost to enter the raffle.
`i_interval`: The duration of the lottery in seconds.
`s_players`: An array to store the addresses of all participants.
`s_recentWinner`: The address of the most recent winner.
`s_raffleState`: An enum (`OPEN`, `CALCULATING`) representing the current state of the lottery.
`i_keyHash`: The gas lane key hash for the VRF service.
`i_subscriptionId`: The subscription ID for the Chainlink VRF service.
Events:
`RaffleEntered(address indexed player)`: Emitted when a player enters the raffle.
`WinnerPicked(address indexed winner)`: Emitted when a winner is chosen.
`RequestedRaffleWinner(uint256 indexed requestId)`: Emitted when a request for a random winner is sent to the VRF coordinator.

Key Functions:
`enterRaffle()`: Allows a user to enter the lottery by sending the required entrance fee.
`checkUpkeep()`: This function is called by Chainlink Automation nodes to verify if it's time to pick a winner. It checks if the time interval has passed, the lottery is open, and there are players and a balance.
`PerformUpkeep()`: If checkUpkeep returns true, this function is executed. It requests a random number from the Chainlink VRF coordinator.
`fulfillRandomWords()`: This callback function is called by the VRF coordinator with the random number. It uses the random number to select a winner, reset the lottery, and send the prize money.

`script/DeployRaffle.s.sol`
This script handles the deployment of the `Raffle` contract. It uses the `HelperConfig` script to fetch the correct parameters for the chosen network. The script also manages the creation and funding of a VRF subscription and adds the new `Raffle` contract as an authorized consumer.

`script/HelperConfig.s.sol`
This contract manages network-specific configurations. It provides the appropriate parameters (e.g., `vrfCoordinator` address, `entranceFee`, `subscriptionId`) for different chains like Sepolia and local Anvil. For local testing, it deploys mock versions of the `VRFCoordinatorV2_5Mock` and `LinkToken`.

`script/Interactions.s.sol`
This file contains scripts for managing the Chainlink VRF subscription.
`CreateSubscription`: Creates a new subscription with the VRF coordinator.
`FundSubscription`: Funds the created subscription with LINK tokens.
`AddConsumer`: Adds the deployed `Raffle` contract address to the subscription as an approved consumer.

Testing
The project includes a comprehensive test suite divided into three main categories: unit, integration, and staging tests.

Unit Tests (`test/unit/RaffleTest.t.sol`)
These tests focus on the individual functions of the `Raffle.sol` contract in isolation. They verify:

The initial state of the contract upon deployment.
Correct handling of player entries and fees.
State changes during different phases of the lottery.
The logic of the `checkUpkeep` and `PerformUpkeep` functions.
The winner selection and fund transfer process in `fulfillRandomWords` using a mocked VRF response.

Integration Tests (`test/integration/`)
These tests ensure that different parts of the system work together as expected on a local Anvil network.
`DeployRaffleTest.t.sol`: Tests the entire deployment process, including subscription creation, funding, and adding a consumer, ensuring the `Raffle` contract is deployed and configured correctly.
`HelperConfigTest.t.sol`: Verifies that the `HelperConfig` contract returns the correct configurations for both Sepolia and local Anvil networks.
`InteractionsTests.t.sol`: Tests the VRF subscription scripts (`CreateSubscription`, `FundSubscription`, `AddConsumer`) to confirm they interact correctly with the mock VRF coordinator.

Staging Tests (`test/staging/RaffleTest.t.sol`)
These tests are designed to be run on a live testnet (like Sepolia) by forking it. They validate the end-to-end functionality of the lottery in a production-like environment, ensuring it integrates correctly with live Chainlink services. The key test, `testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney`, verifies the full cycle from upkeep to randomly selecting a winner and distributing the prize.

Mocks
`LinkToken.sol`: A mock ERC20 LinkToken contract used for local testing. It includes the `transferAndCall` function required for funding VRF subscriptions.





