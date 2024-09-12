// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    // Scope Fundme contract to the entire contract
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    // Runs first
    function setUp() external {
        // Deploy fundme contract
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);

        // Create new deployfundmecontract
        // Now our tests match whatever change we've made in deploy script
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();

        // Give USER some ether to start with
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public {
        // Assert equal
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        console.log(fundMe.getOwner());
        console.log(msg.sender);
        console.log(address(this));
        // address(this) cause in this test the test contract is the one deploying the contract not msg.sender (i.e owner of fundMe is fundMeTest not us)
        // So check to see if fundMe test is the owner
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        // Assert that version is 4
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        // This expects the next line to revert else returna an error if it doesn't
        vm.expectRevert();

        // This should fail because we not sending enough ETH whan calling fund function
        fundMe.fund();

        // Hence test passes
    }

    // Check that data containers (map) are updated after a succesful fund() transaction
    function testFundUpdatesFundedDataStructure() public {
        // prank cheatcode specifies who will send the next tx
        vm.prank(USER); //USER will send the next transaction
        // send a fund transaction of SEND_VALUE (0.1 eth) by USER
        fundMe.fund{value: SEND_VALUE}();

        // Check amount USER sent
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        // check that amountfunded is same as amount User sent
        assertEq(amountFunded, SEND_VALUE);
    }

    // check that funders list is updated
    function testAddsFundersToArrayOfFunders() public {
        // Send tx from USER
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        // Get the only funder i.e (USER)
        address funder = fundMe.getFunder(0);
        // check that fuinder is user
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    // Check that only contract owner can trigger withdraw function
    function testOnlyOwnerCanWithdraw() public funded {
        // Send tx from USER
        // vm.prank(USER);
        // fundMe.fund{value: SEND_VALUE}();

        // USER should trigger 'withdraw tx'
        // Since USER isnt contract owner, tx should fail i.e (expect revert)
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    // Test withdrawal with contract owner
    function testWithDrawWithSingleFunder() public funded {
        // Arrange
        // Starting balance of owner
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        // Starting balance of contract (SEND_VALUE) in this case
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        // Execute withdraw function with contract owner
        // uint256 gasStart = gasleft(); //e.g 1000
        // vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner()); //e.g 200
        fundMe.withdraw();
        // uint256 gasEnd = gasleft(); //e,g 800
        // // gas used from withdraw transaction
        // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        // console.log(gasUsed);

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        // Balance after withdraw tx
        uint256 endingFundMeBalance = address(fundMe).balance;
        // Check that balance after withdraw tx is 0
        assertEq(endingFundMeBalance, 0);
        // check that money from the contract has been added to the owner balance after withdraw tx
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        // 10 users funding the contract
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // create a blank address of 'i' and we'll add SEND_VALUE
            // "hoax" performs both 'prank' and 'deal'
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        // Starting balance of owner
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        // Starting balance of contract (SEND_VALUE) in this case
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        // Execute withdraw function with contract owner
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // Assert
        // Check that we've removed all the funds from fundMe
        assert(address(fundMe).balance == 0);

        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        // 10 users funding the contract
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // create a blank address of 'i' and we'll add SEND_VALUE
            // "hoax" performs both 'prank' and 'deal'
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        // Starting balance of owner
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        // Starting balance of contract (SEND_VALUE) in this case
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        // Execute withdraw function with contract owner
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        // Assert
        // Check that we've removed all the funds from fundMe
        assert(address(fundMe).balance == 0);

        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }
}
