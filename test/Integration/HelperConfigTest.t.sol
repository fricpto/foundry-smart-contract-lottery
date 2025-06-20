// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {HelperConfig, codeConstants} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

contract HelperConfigTest is Test, codeConstants {
    // Contracts
    HelperConfig public helperConfig;

    function setUp() public {
        // Deploy HelperConfig
        helperConfig = new HelperConfig();
    }

    // Test: Verify Sepolia configuration
    function testGetSepoliaConfig() public {
        // Sepolia chain ID
        uint256 sepoliaChainId = ETH_SEPOLIA_CHAIN_ID;
        vm.chainId(sepoliaChainId);

        // Get config
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        // Assertions
        assertEq(
            config.vrfCoordinator,
            0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            "Incorrect VRF Coordinator address for Sepolia"
        );
        assertEq(config.link, 0x779877A7B0D9E8603169DdbD7836e478b4624789, "Incorrect LINK token address for Sepolia");
        assertEq(
            config.subscriptionId,
            54603143993479064344964788141058857577595608566123857895607497288715602956053,
            "Incorrect subscription ID for Sepolia"
        );
        assertEq(config.account, 0x3230AFf184EF0C815C0163d8bbbD53CCaB420A9d, "Incorrect account address for Sepolia");

        console.log("Sepolia config verified successfully");
    }

    // Test: Verify local Anvil configuration
    function testGetOrCreateAnvilConfig() public {
        // local Anvil chain ID
        uint256 anvilChainId = LOCAL_CHAIN_ID;
        vm.chainId(anvilChainId);

        // Get config
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        // Assertions
        assertTrue(config.vrfCoordinator != address(0), "VRF Coordinator address should not be zero");
        assertTrue(config.link != address(0), "LINK token address should not be zero");
        assertEq(config.subscriptionId, 0, "Subscription ID should be zero for local Anvil");
        assertEq(
            config.account, 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38, "Incorrect account address for local Anvil"
        );

        console.log("Local Anvil config verified successfully");
    }

    // Test: Verify invalid chain ID reverts
    function testInvalidChainIdReverts() public {
        // unsupported chain ID
        uint256 invalidChainId = 12345;
        vm.chainId(invalidChainId);

        // Expect revert when getting config for an invalid chain ID
        vm.expectRevert(HelperConfig.HelperConfig__InvalidChainId.selector);
        helperConfig.getConfig();

        console.log("Invalid chain ID reverted as expected");
    }

    // Test: Verify mock contracts are deployed for local Anvil
    function testMockContractsDeployed() public {
        // local Anvil chain ID
        uint256 anvilChainId = LOCAL_CHAIN_ID;
        vm.chainId(anvilChainId);

        // Get config
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        // Assertions
        assertTrue(config.vrfCoordinator != address(0), "VRF Coordinator address should not be zero");
        assertTrue(config.link != address(0), "LINK token address should not be zero");

        // Verify VRFCoordinatorV2_5Mock is deployed
        VRFCoordinatorV2_5Mock coordinator = VRFCoordinatorV2_5Mock(config.vrfCoordinator);

        // Create a subscription
        vm.startBroadcast(config.account);
        uint256 subId = coordinator.createSubscription();
        vm.stopBroadcast();

        (uint96 balance,,,,) = coordinator.getSubscription(subId);

        assertEq(balance, 0, "VRF Coordinator subscription balance should be zero");

        // Verify LinkToken is deployed
        LinkToken link = LinkToken(config.link);
        assertEq(link.balanceOf(address(this)), 0, "LINK token balance should be zero");

        console.log("Mock contracts deployed successfully for local Anvil");
    }
}
