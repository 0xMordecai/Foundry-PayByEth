// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {Genesis} from "../src/PayByEth.sol";

contract DeployGenesis is Script {
    function run() external returns (Genesis) {
        vm.startBroadcast();
        Genesis genesis = new Genesis();
        vm.stopBroadcast();

        return genesis;
    }
}
