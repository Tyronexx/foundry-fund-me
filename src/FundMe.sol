// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Note: The AggregatorV3Interface might be at a different location than what was in the video!
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    // Storage variables (start with "s")
    // map of addresses and amount each of them sent
    mapping(address => uint256) private s_addressToAmountFunded;
    // List of people (addresses) that send money to 'fund' contract
    address[] private s_funders;

    // Could we make this constant?  /* hint: no! We should make it immutable! */
    // only contract owner should be able to call withdraw function
    // Theres no message.sender inside the global scope asides inside a functon i.e constructor function
    // this will be the contract owner
    // Immutable variables start with "i"
    address private immutable i_owner;
    uint256 public constant MINIMUM_USD = 5 * 10 ** 18;
    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        // owner is set to whoever deploys this contract
        i_owner = msg.sender;

        // Whenever we deploy the contract, aggregatorv3interface gets set to the contract we want to use, and this contract is dependent on the network we're deploying to
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "You need to spend more ETH!"
        );
        // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
        s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        return s_priceFeed.version();
    }

    modifier onlyOwner() {
        // require(msg.sender == owner);
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }

    // Read and write from storage alot less
    function cheaperWithdraw() public onlyOwner {
        // Read from storage once and store it in memory
        uint256 fundersLength = s_funders.length;
        for (
            uint256 funderIndex = 0;
            funderIndex < fundersLength;
            funderIndex++
        ) {
            // get each funder
            address funder = s_funders[funderIndex];
            // update specified funder amount to 0 (cause money has been withdrawn)
            s_addressToAmountFunded[funder] = 0;
        }
        // reset array
        // reset funders array to a brand new address array with 0 objects
        s_funders = new address[](0);
        // // transfer
        // payable(msg.sender).transfer(address(this).balance);

        // // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        // call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    function withdraw() public onlyOwner {
        // check that message.sender is same as owner of contract before executing function
        // 'onlyOwner' modifier does same
        // require(msg.sender == owner, "Sender is not owner");

        // since we're withdrawing all the funds, we want to reset our "funders" array and address to amount map (i.e, each address now has 0)
        /* for(starting index, condition, step)*/
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            // get each funder
            address funder = s_funders[funderIndex];
            // update specified funder amount to 0 (cause money has been withdrawn)
            s_addressToAmountFunded[funder] = 0;
        }
        // reset array
        // reset funders array to a brand new address array with 0 objects
        s_funders = new address[](0);
        // // transfer
        // payable(msg.sender).transfer(address(this).balance);

        // // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        // call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    // Explainer from: https://solidity-by-example.org/fallback/
    // Ether is sent to contract
    //      is msg.data empty?
    //          /   \
    //         yes  no
    //         /     \
    //    receive()?  fallback()
    //     /   \
    //   yes   no
    //  /        \
    //receive()  fallback()

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }

    /**
     * View/Pure functions (Getters) cause storage variables are private
     */
    // Get amount funded for given address from map
    function getAddressToAmountFunded(
        address fundingAddress
    ) external view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    // From funders list, get funder based on index
    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}

// Concepts we didn't cover yet (will cover in later sections)
// 1. Enum
// 2. Events
// 3. Try / Catch
// 4. Function Selector
// 5. abi.encode / decode
// 6. Hash with keccak256
// 7. Yul / Assembly
