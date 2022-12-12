// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract BlindAuction {
    // 出价
    struct Bid {
        bytes32 blindedBid;
        uint256 deposit;
    }
    // 受益人地址
    address payable public beneficiary;
    // 出价结束时间
    uint256 public biddingEndTime;
    // 公示结束时间
    uint256 public revealEndTime;
    // 最高出价者地址
    address public highestBidder;
    // 最高出价
    uint256 public highestBid;
    // 拍卖结束标志
    bool ended;
    // 被超报价集合
    mapping(address => uint256) pendingReturns;
    // 出价集合
    mapping(address => Bid[]) public bids;

    // 拍卖结束
    event AuctionEnded(address winner, uint256 amount);

    /// Try again at `time`.
    error TooEarly(uint256 time);
    /// It can't be called after `time`.
    error TooLate(uint256 time);
    /// The function auctionEnd has already been called.
    error AuctionEndAlreadyCalled();

    // 校验
    modifier onlyBefore(uint256 time) {
        if (block.timestamp >= time) revert TooLate(time);
        _;
    }
    modifier onlyAfter(uint256 time) {
        if (block.timestamp >= time) revert TooEarly(time);
    }

    // 构造函数
    constructor(
        uint256 biddingTime,
        uint256 revealTime,
        address payable beneficiary_
    ) {
        beneficiary = beneficiary_;
        biddingEndTime = block.timestamp + biddingTime;
        revealEndTime = biddingEndTime + revealTime;
    }

    /// 出价
    function bid(bytes32 blindedBid)
        external
        payable
        onlyBefore(biddingEndTime)
    {
        bids[msg.sender].push(
            Bid({blindedBid: blindedBid, deposit: msg.value})
        );
    }

    /// 公示
    function reval(
        uint256[] calldata values,
        bool[] calldata fakes,
        bytes32[] calldata secrets
    ) external onlyAfter(biddingEndTime) onlyBefore(revealEndTime) {
        uint256 len = bids[msg.sender].length;
        require(values.length == len);
        require(fakes.length == len);
        require(secrets.length == len);

        uint256 refund;
        for (uint256 i = 0; i < len; i++) {
            Bid storage bidToCheck = bids[msg.sender][i];
            (uint256 value, bool fake, bytes32 secret) = (
                values[i],
                fakes[i],
                secrets[i]
            );
            if (bidToCheck.blindedBid != keccak256(value, fake, secret)) {
                continue;
            }
            refund += bidToCheck.deposit;
            if (!fake && bidToCheck.deposit >= value) {
                if (placeBid(msg.sender, value)) refund -= value;
            }
            bidToCheck.blindedBid = bytes32(0);
        }
        payable(msg.sender).transfer(refund);
    }

    // 比较出价，被超过的报价会进行记录
    function placeBid(address bidder, uint256 value)
        internal
        returns (bool success)
    {
        if (value <= highestBid) return false;
        if (highestBidder != address(0))
            pendingReturns[highestBidder] += highestBid;
        highestBid = value;
        highestBidder = bidder;
        return true;
    }

    /// 取回退还
    function withdraw() external{
        // 获取需退数量
        uint256 amount = pendingReturns[msg.sender];
        if (amount > 0) {
            // 清空并转移
            pendingReturns[msg.sender] = 0;
            payable(msg.sender).transfer(amount);
        }
    }

    /// 结算拍卖
    function auctionEnd() external onlyAfter(revealEndTime){
        // 如果已经结算过了
        if (ended) revert AuctionEndAlreadyCalled();
        // 执行
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);
        // 转账
        beneficiary.transfer(highestBid);
    }
}
