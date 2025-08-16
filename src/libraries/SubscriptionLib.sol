// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title SubscriptionLib
 * @author Yordan Proshin
 * @notice A reusable library for managing on-chain subscriptions with ERC-20 tokens.
 * Inspired by trustless automation patterns from Sub2 and Subs Protocol.
 */
library SubscriptionLib {
    /**
     * @notice Subscription model for recurring payments
     * @param user Wallet address of subscriber
     * @param provider Wallet address of service
     * param token Token used for payment (e.g., USDC, DAI)
     * @param amount Amount to charge per interval
     * @param interval Time between payments in seconds (e.g., 30 days)
     * @param lastPaid Timestamp of last successful payment
     * @param isActive Whether subscription is active
     * @param isPaused Whether subscription is paused (optional use)
     * @param paymentId Unique ID for this payment stream
     */
    struct Subscription {
        address user;
        address provider;
        address token;
        uint256 amount;
        uint256 interval;
        uint256 lastPaid;
        bool isActive;
        bool isPaused;
        uint256 paymentId;
    }

    /**
     * @notice Thrown when subscription is not active
     */
    error SubNotActive();

    /**
     * @notice Thrown when interval has not elapsed
     */
    error IntervalNotElapsed();

    /**
     * @notice Emitted when a new subscription is created
     */
    event SubscriptionCreated(
        uint256 indexed paymentId,
        address indexed user,
        address indexed provider,
        address token,
        uint256 amount,
        uint256 interval
    );

    /**
     * @notice Emitted when a subscription is paid
     */
    event SubscriptionPaid(uint256 indexed paymentId, uint256 amount, uint256 timestamp);

    /**
     * @notice Create a new subscription
     * @param self The subscription storage reference
     * @param _user Subscriber address
     * @param _provider Provider address
     * @param _token ERC-20 token address
     * @param _amount Amount to charge
     * @param _interval Time between charges
     * @param _paymentId Unique identifier
     */
    function create(
        Subscription storage self,
        address _user,
        address _provider,
        address _token,
        uint256 _amount,
        uint256 _interval,
        uint256 _paymentId
    ) external {
        if (_user == address(0)) revert("User zero address");
        if (_provider == address(0)) revert("Provider zero address");
        if (_token == address(0)) revert("Token zero address");
        if (_amount == 0) revert("Zero amount");
        if (_interval < 1 hours) revert("Interval too short");

        self.user = _user;
        self.provider = _provider;
        self.token = _token;
        self.amount = _amount;
        self.interval = _interval;
        self.lastPaid = block.timestamp;
        self.isActive = true;
        self.isPaused = false;
        self.paymentId = _paymentId;

        emit SubscriptionCreated(_paymentId, _user, _provider, _token, _amount, _interval);
    }

    /**
     * @notice Check if subscription is due for payment
     * @param self The subscription
     * @return bool True if payment is due
     */
    function isDue(Subscription storage self) external view returns (bool) {
        return (self.isActive && !self.isPaused && block.timestamp >= self.lastPaid + self.interval);
    }

    function Days(uint256 n) internal pure returns (uint256) {
        return n * 86400;
    }
}
