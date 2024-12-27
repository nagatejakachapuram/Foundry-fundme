// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    address OWNER = address(this); // Test contract address as deployer
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant SEND_VALUE = 0.1 ether;

    MockV3Aggregator mockPriceFeed;

    function setUp() external {
        vm.deal(USER, STARTING_BALANCE);
        vm.deal(OWNER, STARTING_BALANCE);

        // Set up contract with mock price feed for Anvil (local testing)
        mockPriceFeed = new MockV3Aggregator(8, 2000e8); // Mock with 8 decimals and $2000
        vm.prank(OWNER); // Set deployer context to OWNER
        fundMe = new FundMe(address(mockPriceFeed));
    }

    function testOwnerIsMsgSender() public view {
        address contractOwner = fundMe.getOwner();
        assertEq(contractOwner, OWNER, "Owner should be the deployer");
    }

    function testWithdrawFromMultipleFunders() public {
        // Arrange: Fund contract with multiple funders
        uint160 numberOfFunders = 10;
        for (uint160 i = 1; i <= numberOfFunders; i++) {
            address funder = address(uint160(i));
            vm.deal(funder, SEND_VALUE);
            vm.prank(funder);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = OWNER.balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        emit log_named_uint("Starting FundMe Balance", startingFundMeBalance);
        emit log_named_uint("Starting Owner Balance", startingOwnerBalance);

        // Act: Withdraw funds as the owner
        vm.startPrank(OWNER);
        try fundMe.withdraw() {
            emit log("Withdraw successful");
        } catch Error(string memory reason) {
            emit log_named_string("Revert Reason", reason);
            fail();
        } catch (bytes memory lowLevelData) {
            emit log_named_bytes("Low-level Revert Data", lowLevelData);
            fail();
        }
        vm.stopPrank();

        // Assert: Check balances after withdrawal
        uint256 endingOwnerBalance = OWNER.balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        emit log_named_uint("Ending FundMe Balance", endingFundMeBalance);
        emit log_named_uint("Ending Owner Balance", endingOwnerBalance);

        assertEq(endingFundMeBalance, 0, "Contract balance should be 0");
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance,
            "Owner's balance should increase by the contract balance"
        );
    }
}

