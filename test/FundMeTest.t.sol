// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address constant SEPOLIA_PRICE_FEED =
        0x694AA1769357215DE4FAC081bf1f309aDC325306;
    address constant MAINNET_PRICE_FEED =
        0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

    function setUp() external {
        if (block.chainid == 11155111) {
            fundMe = new FundMe(SEPOLIA_PRICE_FEED);
        } else if (block.chainid == 1) {
            fundMe = new FundMe(MAINNET_PRICE_FEED);
        } else {
            revert("Unsupported chain");
        }
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18, "Minimum USD should be 5e18");
    }

    function testOwnerIsMsgSender() public view {
        assertEq(
            fundMe.i_owner(),
            address(this),
            "Owner should be the deployer"
        );
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        if (block.chainid == 11155111) {
            assertEq(version, 4, "Version should be 4 on Sepolia");
        } else if (block.chainid == 1) {
            assertEq(version, 6, "Version should be 6 on Mainnet");
        }
    }
}
