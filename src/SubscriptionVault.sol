// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract SubscriptionVault is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    IERC20 public paymentToken;

    struct Subscription {
        address subscriber;
        address merchant;
        address token;
        uint256 amount;
        uint256 interval;
        uint256 lastPaid;
        uint256 nextDue;
        bool active;
    }

    mapping(bytes32 => Subscription) public _subscriptions;
    mapping(address => bytes32[]) public _userSubscriptions;

    constructor(IERC20 _token) Ownable(msg.sender) {
        paymentToken = _token;
    }

    event SubscriptionCreated(bytes32 indexed id, address subscriber, address merchant, address token, uint256 amount);
    event PaymentProcessed(bytes32 indexed id, uint256 timestamp, bool success);
    event SubscriptionCancelled(bytes32 indexed id);

    function createSubscription(address _merchant, address _token, uint256 _amount, uint256 _interval)
        external
        returns (bytes32)
    {
        bytes32 subId = keccak256(abi.encodePacked(msg.sender, _merchant, block.timestamp));

        _subscriptions[subId] = Subscription({
            subscriber: msg.sender,
            merchant: _merchant,
            token: _token,
            amount: _amount,
            interval: _interval,
            lastPaid: block.timestamp,
            nextDue: block.timestamp + _interval,
            active: true
        });

        _userSubscriptions[msg.sender].push(subId);

        emit SubscriptionCreated(subId, msg.sender, _merchant, _token, _amount);
        return subId;
    }

    function processPayment(bytes32 _subId) external nonReentrant {
        Subscription storage sub = _subscriptions[_subId];
        require(sub.active, "Inactive subscription");
        require(block.timestamp >= sub.nextDue, "Not due yet");

        bool success = IERC20(sub.token).transferFrom(sub.subscriber, sub.merchant, sub.amount);

        if (success) {
            sub.lastPaid = block.timestamp;
            sub.nextDue = block.timestamp + sub.interval;
            emit PaymentProcessed(_subId, block.timestamp, true);
        } else {
            sub.active = false;
            emit SubscriptionCancelled(_subId);
        }
    }

    function cancelSubscription(bytes32 _subId) external {
        Subscription storage sub = _subscriptions[_subId];
        require(sub.subscriber == msg.sender, "Not subscriber");
        sub.active = false;
        emit SubscriptionCancelled(_subId);
    }

    function getSubscriptionsForUser(address user) external view returns (Subscription[] memory) {
        bytes32[] memory ids = _userSubscriptions[user];
        Subscription[] memory subs = new Subscription[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            subs[i] = _subscriptions[ids[i]];
        }
        return subs;
    }

    function subscriptions(bytes32 id) external view returns (Subscription memory) {
        return _subscriptions[id];
    }

    function getSubscription(bytes32 subId)
        external
        view
        returns (
            address subscriber,
            address merchant,
            address token,
            uint256 amount,
            uint256 interval,
            uint256 lastPaid,
            uint256 nextDue,
            bool active
        )
    {
        Subscription storage sub = _subscriptions[subId];
        return
            (sub.subscriber, sub.merchant, sub.token, sub.amount, sub.interval, sub.lastPaid, sub.nextDue, sub.active);
    }
}
