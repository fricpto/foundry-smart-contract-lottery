// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {HelperConfig, codeConstants} from "script/HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "script/Interactions.s.sol";
import {Raffle} from "src/Raffle.sol";

contract InteractionTests is Test, codeConstants {
    // Contracts
    HelperConfig public helperConfig;
    CreateSubscription public createSubscription;
    FundSubscription public fundSubscription;
    AddConsumer public addConsumer;
    Raffle public raffle;

    // Addresses
    address public vrfCoordinator;
    address public linkToken;
    address public account;

    // Subscription ID
    uint256 public subscriptionId;

    function setUp() public {
        // Deploy HelperConfig
        helperConfig = new HelperConfig();

        // Get network config
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        // Assign addresses
        vrfCoordinator = config.vrfCoordinator;
        linkToken = config.link;
        account = config.account;

        // Deploy Interaction contracts
        createSubscription = new CreateSubscription();
        fundSubscription = new FundSubscription();
        addConsumer = new AddConsumer();

        // Deploy Raffle contract
        vm.startBroadcast(account);
        raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();
    }

    // Test: Create a subscription
    function testcreateSubscription() public {
        // Create a subscription
        (uint256 subId, address coordinator) = createSubscription.createSubscription(vrfCoordinator, account);

        // Assertions
        assertTrue(subId > 0, "Subscription ID should be greater than 0");
        assertEq(coordinator, vrfCoordinator, "VRF Coordinator address should match");

        console.log("Subscription ID created: ", subId);
    }

    // Test: Fund a subscription
    function testfundSubscription() public {
        // Create a subscription first
        (uint256 subId,) = createSubscription.createSubscription(vrfCoordinator, account);

        // Fund the subscription
        fundSubscription.fundSubscription(vrfCoordinator, subId, linkToken, account);

        // Assertions
        if (block.chainid == LOCAL_CHAIN_ID) {
            // On local chain, check the subscription balance
            VRFCoordinatorV2_5Mock coordinator = VRFCoordinatorV2_5Mock(vrfCoordinator);
            (uint96 balance,,,,) = coordinator.getSubscription(subId);
            assertEq(
                balance, fundSubscription.FUND_AMOUNT() * 100, "Subscription should be funded with the correct amount"
            );
        } else {
            // On live networks, check Link token balance
            LinkToken link = LinkToken(linkToken);
            uint256 balance = link.balanceOf(vrfCoordinator);
            assertTrue(balance >= fundSubscription.FUND_AMOUNT(), "VRF Coordinator should have received LINK tokens");
        }

        console.log("Subscription funded: ", subId);
    }

    // Test: Add a consumer to the subscription
    function testaddConsumer() public {
        // Create and fund a subscription first
        (uint256 subId,) = createSubscription.createSubscription(vrfCoordinator, account);
        fundSubscription.fundSubscription(vrfCoordinator, subId, linkToken, account);

        // Add the Raffle contract as a consumer
        addConsumer.addConsumer(address(raffle), vrfCoordinator, subId, account);

        // Assertions
        VRFCoordinatorV2_5Mock coordinator = VRFCoordinatorV2_5Mock(vrfCoordinator);

        // Get the list of consumers for the subscription
        (,,,, address[] memory consumers) = coordinator.getSubscription(subId);

        // Check if the Raffle contract is in the consumers list
        bool isConsumer = false;
        for (uint256 i = 0; i < consumers.length; i++) {
            if (consumers[i] == address(raffle)) {
                isConsumer = true;
                break;
            }
        }

        assertTrue(isConsumer, "Raffle contract should be a consumer");

        console.log("Consumer added: ", address(raffle));
    }
    // Test: Full deployment flow (create subscription, fund it, add consumer)

    function testFullDeploymentFlow() public {
        // Create subscription
        (uint256 subId,) = createSubscription.createSubscription(vrfCoordinator, account);

        // Fund subscription
        fundSubscription.fundSubscription(vrfCoordinator, subId, linkToken, account);

        // Add consumer
        addConsumer.addConsumer(address(raffle), vrfCoordinator, subId, account);

        // Assertions
        VRFCoordinatorV2_5Mock coordinator = VRFCoordinatorV2_5Mock(vrfCoordinator);
        // Get the list of consumers for the subscription
        (,,,, address[] memory consumers) = coordinator.getSubscription(subId);

        // Check if the Raffle contract is in the consumers list
        bool isConsumer = false;
        for (uint256 i = 0; i < consumers.length; i++) {
            if (consumers[i] == address(raffle)) {
                isConsumer = true;
                break;
            }
        }
        assertTrue(isConsumer, "Raffle contract should be a consumer");

        console.log("Full deployment flow completed successfully");
    }
}
