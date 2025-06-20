// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "script/Interactions.s.sol"; // Add missing imports
import {DeployRaffle} from "script/DeployRaffle.s.sol";

contract DeployRaffleTest is Test {
    // State variables
    Raffle public raffle;
    HelperConfig public helperConfig;
    address public vrfCoordinator;
    address public linkToken;
    address public account;
    uint256 public subscriptionId;

    function testDeployRaffleOnLocalAnvil() public {
        // local Anvil chain ID
        uint256 anvilChainId = 31337;
        vm.chainId(anvilChainId);

        // Deploy HelperConfig
        helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        console.log("Initial subscription ID: ", config.subscriptionId);

        // Create a subscription if it doesn't exist
        if (config.subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            (config.subscriptionId, config.vrfCoordinator) =
                createSubscription.createSubscription(config.vrfCoordinator, config.account);

            console.log("Created subscription ID: ", config.subscriptionId);

            // Fund the subscription
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(config.vrfCoordinator, config.subscriptionId, config.link, config.account);

            console.log("Funded subscription ID: ", config.subscriptionId);
        }

        // Deploy Raffle
        vm.startBroadcast(config.account);
        raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        console.log("Raffle deployed at: ", address(raffle));

        // Add Raffle as a consumer
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(raffle), config.vrfCoordinator, config.subscriptionId, config.account);

        console.log("Raffle added as a consumer to subscription ID: ", config.subscriptionId);

        // Assign values for assertions
        vrfCoordinator = config.vrfCoordinator;
        linkToken = config.link;
        account = config.account;
        subscriptionId = config.subscriptionId;

        // Assertions
        assertTrue(address(raffle) != address(0), "Raffle contract should be deployed");
        assertTrue(vrfCoordinator != address(0), "VRF Coordinator address should not be zero");
        assertTrue(linkToken != address(0), "LINK token address should not be zero");
        assertTrue(subscriptionId > 0, "Subscription ID should be greater than zero");

        // Verify Raffle is added as a consumer
        VRFCoordinatorV2_5Mock coordinator = VRFCoordinatorV2_5Mock(vrfCoordinator);

        (,,,, address[] memory consumers) = coordinator.getSubscription(subscriptionId);

        bool isConsumer = false;
        for (uint256 i = 0; i < consumers.length; i++) {
            if (consumers[i] == address(raffle)) {
                isConsumer = true;
                break;
            }
        }

        assertTrue(isConsumer, "Raffle contract should be a consumer");

        console.log("Raffle deployed successfully on local Anvil");
    }

    // Test: Verify Raffle deployment on Sepolia
    // function testDeployRaffleOnSepolia() public {
    //     // Switch to Sepolia chain ID
    //     uint256 sepoliaChainId = 11155111;
    //     vm.chainId(sepoliaChainId);

    //     // Deploy DeployRaffle script
    //     DeployRaffle deployRaffle = new DeployRaffle();

    //     // Deploy Raffle and get the deployed contract and helper config
    //     (Raffle deployedRaffle, HelperConfig helperCfg) = deployRaffle
    //         .deployContract();

    //     // Get the network config
    //     HelperConfig.NetworkConfig memory config = helperCfg.getConfig();

    //     // Assign values for assertions
    //     raffle = deployedRaffle;
    //     vrfCoordinator = config.vrfCoordinator;
    //     linkToken = config.link;
    //     account = config.account;
    //     subscriptionId = config.subscriptionId;

    //     // Skip the entire AddConsumer flow for Sepolia
    //     console.log(
    //         "Skipping consumer addition in test - already manually added via Chainlink dashboard"
    //     );

    //     // Assert deployment was successful
    //     assertTrue(address(raffle) != address(0), "Raffle should be deployed");
    //     assertEq(
    //         vrfCoordinator,
    //         0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
    //         "Correct VRF Coordinator"
    //     );
    //     assertEq(
    //         linkToken,
    //         0x779877A7B0D9E8603169DdbD7836e478b4624789,
    //         "Correct LINK token"
    //     );
    //     assertTrue(subscriptionId > 0, "Valid subscription ID");

    //     console.log("Raffle successfully deployed at:", address(raffle));
    //     console.log("Using subscription:", subscriptionId);

    // You must manually add the consumer via Chainlink's VRF dashboard

    // Ensure your subscription is funded with LINK

    // Use the exact contract address deployed in the test

    // }
}
