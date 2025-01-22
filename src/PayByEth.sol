// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title PayByEth
 * @author Lahrach Mohamed
 * @notice this contract is used to pay for a service using Ether
 */
contract Genesis {
    error Genesis__SendMoreEth();
    error Genesis__TransferFailed();
    error Genesis__InvalidSender();
    error Genesis__InvalidReceiver();
    error Genesis__RefundFailed();
    error Genesis__DirectPaymentNotAllowed();

    struct Payment {
        address from;
        address to;
        uint256 price;
        uint256 payment_date;
        uint256 product_id;
    }
    /**
     * @dev when a payment made me emit an event that contains purchace data
     */
    event PaymentMade(
        address indexed payer,
        address indexed seller,
        uint256 price,
        uint256 product_id,
        uint256 payment_date
    );
    /**
     * @dev when sender sends more than the price of the product we refund it back and emit an event
     */
    event RefundMade(address indexed payer, uint256 refundAmount);

    /**
     * @dev when a direct payment is made we revert it and emit an event
     */
    event DirectPaymentRejected(address indexed sender, uint256 amount);

    function Pay(
        address _receiver,
        uint256 _price,
        uint256 _productId
    ) public payable {
        if (msg.value < _price) {
            revert Genesis__SendMoreEth();
        }
        uint256 refund = msg.value - _price;
        if (refund > 0) {
            (bool success, ) = msg.sender.call{value: refund}("");
            if (!success) {
                revert Genesis__RefundFailed();
            }
            // After refunding we emit RefundMade event
            _recordRefund(msg.sender, refund);
        }
        // refund the remaining Ether

        // Effect before interaction (state changes first)
        _recordPayment(_receiver, _price, _productId);

        // Transfer funds last (interaction)
        _transfer(_receiver, _price);
    }

    function _transfer(address to, uint256 amount) public {
        if (msg.sender == address(0)) {
            revert Genesis__InvalidSender();
        }
        if (to == address(0)) {
            revert Genesis__InvalidReceiver();
        }

        _send(to, amount);
    }

    function _send(address to, uint256 amount) public virtual {
        (bool success, ) = to.call{value: amount}("");
        if (!success) {
            revert Genesis__TransferFailed();
        }
    }

    function _recordPayment(
        address _receiver,
        uint256 _price,
        uint256 _productId
    ) public {
        // Logic to record payment in any mappings or off-chain data
        emit PaymentMade(
            msg.sender,
            _receiver,
            _price,
            _productId,
            block.timestamp
        );
    }

    function _recordRefund(address _sender, uint256 refund_amount) public {
        emit RefundMade(_sender, refund_amount);
    }

    /**
     * @dev receive() function to reject direct payments or log them.
     */
    receive() external payable {
        emit DirectPaymentRejected(msg.sender, msg.value);
        revert Genesis__DirectPaymentNotAllowed();
    }
}
