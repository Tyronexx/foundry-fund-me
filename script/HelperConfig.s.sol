// SPDX-License-Identifier: MIT

// This file will
// 1 deploy mocks when we're on a local anvil chain
// 2 Keep track of contract address across different chains

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    // if we're on a local anvil, we deploy mocks
    // Otherwise, grab existing address from live network
    // This way we dont have to hardcode any contract address into our deployment script

    // To specify which network we're currently on
    NetworkConfig public activeNetworkConfig;

    // Uint8 cause its a decimal
    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    // Create new object of type network config
    // all configs will retujrn a type NetworkConfig
    struct NetworkConfig {
        address priceFeed; //ETHUSD price feed
    }

    // Set active network
    constructor() {
        // use chainlist.org for chain id's
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    // Each function represents a chain

    // Memory because this is a special object
    // Sepolia configuration
    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaConfig;
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // 1. Deploy Mocks (fake contracts)
        // 2. Return the mock addressed

        // This checks if we've deployed a price feed before
        // we add this cause if we've deployed one price feed we dont want to deploy a new one
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast();
        // create fake price feed for anvil
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(
            DECIMALS,
            INITIAL_PRICE
        );
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: address(mockPriceFeed)
        });

        return anvilConfig;
    }
}
