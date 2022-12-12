// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract SimpleAuction {
    // 受益人地址
    address payable public beneficiary;
    // 拍卖结束时间
    uint256 public auctionEndTime;
    // 最高出价者地址
    address public highestBidder;
    // 最高出价
    uint256 public highestBid;
    // 被超报价集合
    mapping(address => uint256) pendingReturns;
    // 拍卖结束标志
    bool ended;

    // 最高报价变更
    event HighestBidIncreased(address bidder, uint256 amount);
    // 拍卖结束
    event AuctionEnded(address winner, uint256 amount);

    /// The auction has already ended.
    error AuctionAlreadyEnded();
    /// There is already a higher or equal bid.
    error BidNotHighEnough(uint256 highestBid);
    /// The auction has not ended yet.
    error AuctionNotYetEnded();
    /// The function auctionEnd has already been called.
    error AuctionEndAlreadyCalled();

    // 构造函数
    constructor(uint256 biddingTime, address payable beneficiary_) {
        beneficiary = beneficiary_;
        auctionEndTime = block.timestamp + biddingTime;
    }

    /// 出价
    /// 如果没有竞拍成功，会全部退还
    function bid() external payable {
        // 拍卖结束的情况
        if (block.timestamp > auctionEndTime) {
            revert AuctionAlreadyEnded();
        }
        // 出价不够的情况
        if (msg.value <= highestBid) {
            revert BidNotHighEnough(highestBid);
        }
        // 记录之前被超过的竞拍者的退款
        if (highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }
        // 更新最高价者的信息
        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    /// 取回退还
    function withdraw() external returns (bool) {
        // 获取需退数量
        uint256 amount = pendingReturns[msg.sender];
        if (amount > 0) {
            // 归零
            pendingReturns[msg.sender] = 0;

            if (!payable(msg.sender).send(amount)) {
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    /// 结算拍卖
    function auctionEnd() external {
        // 未到结束时间的情况
        if (block.timestamp < auctionEndTime) revert AuctionNotYetEnded();
        // 如果已经结算过了
        if (ended) revert AuctionEndAlreadyCalled();
        // 执行
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);
        // 转账
        beneficiary.transfer(highestBid);
    }
}
