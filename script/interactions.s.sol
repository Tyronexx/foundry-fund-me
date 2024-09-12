// Script to
// Fund &
// Withdraw

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";

// We'll use this to get our most recent deployment  (installed from foundry devops)
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";

import {FundMe} from "../src/FundMe.sol";

// Script to fund FundMe contract
contract FundFundMe is Script {
    uint256 constant SEND_VALUE = 0.01 ether;

    function fundFundMe(address mostRecentlyDeployed) public {
        // payable cause we're sending a value
        FundMe(payable(mostRecentlyDeployed)).fund{value: SEND_VALUE};

        console.log("Funded FundMe with %s", SEND_VALUE);
    }

    // This runs first hence it'll call fundFundMe function
    function run() external {
        // Get CA of most recent deployed version of a contract  (looks into the broadcast folder and picks "run latest")
        address mostRecentDeployment = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );
        vm.startBroadcast();
        fundFundMe(mostRecentDeployment);
        vm.stopBroadcast();
    }
}

// Script to withdraw FundMe contract
contract WithdrawFundMe is Script {
    function withdrawFundMe(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        // payable cause we're sending a value
        FundMe(payable(mostRecentlyDeployed)).withdraw();
        vm.stopBroadcast();
    }

    // This runs first hence it'll call fundFundMe function
    function run() external {
        // Get CA of most recent deployed version of a contract  (looks into the broadcast folder and picks "run latest")
        address mostRecentDeployment = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );
        vm.startBroadcast();
        withdrawFundMe(mostRecentDeployment);
        vm.stopBroadcast();
    }
}
