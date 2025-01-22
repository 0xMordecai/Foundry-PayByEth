// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {Genesis} from "src/PayByEth.sol";
import {DeployGenesis} from "script/deploy.s.sol";

contract TestGenesis is Test {
    // event
    event DirectPaymentRejected(address indexed sender, uint256 amount);

    event RefundMade(address indexed payer, uint256 refundAmount);

    event PaymentMade(
        address indexed payer,
        address indexed seller,
        uint256 price,
        uint256 product_id,
        uint256 payment_date
    );

    Genesis public genesis;
    //sender
    address public SENDER = makeAddr("sender");
    uint256 constant SENDER_ETH = 100 ether;

    // receiver
    address public RECEIVER = makeAddr("receiver");

    uint256 price = 12 ether;
    uint256 productId = 1;
    uint256 refund = 1 ether;

    receive() external payable {}

    function setUp() external {
        DeployGenesis deploy = new DeployGenesis();
        genesis = deploy.run();

        vm.deal(SENDER, SENDER_ETH);
    }

    function testRevertWhenEthIsNotEnough() public {
        // Arrange
        vm.prank(SENDER);
        //// Act / Assert
        vm.expectRevert(Genesis.Genesis__SendMoreEth.selector);
        genesis.Pay(RECEIVER, price, productId);
    }

    function testRevertWhenThereIsDirectPayment() public {
        // Arrange
        vm.prank(SENDER);
        // Act / Assert
        vm.expectRevert(Genesis.Genesis__DirectPaymentNotAllowed.selector);
        payable(address(genesis)).transfer(price);
    }

    function testEmitEventWhenThereIsDirectPayment() public {
        // Arrange
        vm.prank(SENDER);
        // Act
        vm.expectEmit(true, false, false, false, address(genesis));
        emit DirectPaymentRejected(SENDER, price);
        vm.expectRevert(Genesis.Genesis__DirectPaymentNotAllowed.selector);
        // Assert
        payable(address(genesis)).transfer(price);
    }

    function testRevertWhenSenderIsNotValid() public {
        // Arrange
        vm.prank(address(0));
        // Act / Assert
        vm.expectRevert(Genesis.Genesis__InvalidSender.selector);
        genesis._transfer(RECEIVER, 10 ether);
    }

    function testRevertWhenReceiverIsNotValid() public {
        // Arrange
        vm.prank(SENDER);
        // Act / Assert
        vm.expectRevert(Genesis.Genesis__InvalidReceiver.selector);
        genesis._transfer(address(0), 10 ether);
    }

    function test_recordPaymentEmitsEvent() public {
        // Arrange
        vm.prank(SENDER);
        // Act
        vm.expectEmit(true, false, false, false, address(genesis));
        emit PaymentMade(SENDER, RECEIVER, price, productId, block.timestamp);
        // Assert
        genesis._recordPayment(RECEIVER, price, productId);
    }

    function test_recordRefundEmitsEvent() public {
        // Arrange
        vm.prank(SENDER);
        // Act
        vm.expectEmit(true, false, false, false, address(genesis));
        emit RefundMade(SENDER, refund);
        // Assert
        genesis._recordRefund(SENDER, refund);
    }
}
