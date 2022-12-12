// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

/// @title 委托投票
contract Ballot {
    // 投票者
    struct Voter {
        uint256 weight;
        bool voted;
        address delegate;
        uint256 vote;
    }
    // 提案
    struct Proposal {
        bytes32 name;
        uint256 voteCount;
    }
    // 主席
    address public chairperson;
    // 投票者集合
    mapping(address => Voter) public voters;
    // 提案集合
    Proposal[] public proposals;

    // 构造函数
    constructor(bytes32[] memory proposalNames) {
        // 初始化主席
        chairperson = msg.sender;
        voters[chairperson].weight = 1;
        // 初始化提案
        for (uint256 i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({name: proposalNames[i], voteCount: 0}));
        }
    }

    // 赋予投票权
    function giveRightToVote(address voter) external {
        require(msg.sender == chairperson, "No root.");
        require(!voters[voter].voted, "Already voted.");
        voters[voter].weight = 1;
    }

    // 委托投票
    function delegate(address to) external {
        // 引用委托者
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "No right to vote.");
        require(!sender.voted, "Already voted.");
        require(to != msg.sender, "Self-delegation is disallowed.");
        // 寻找最终代理者
        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;
            require(to != msg.sender, "The last delegate can't be yourself.");
        }
        // 引用代理者
        Voter storage delegate_ = voters[to];
        // 限制原来没有投票权限的当代理者
        require(delegate_.weight > 0);
        // 进行票权让渡
        sender.voted = true;
        sender.delegate = to;
        if (delegate_.voted) {
            proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            delegate_.weight += sender.weight;
        }
    }

    // 投票
    function vote(uint256 proposal_id) external {
        // 引用投票者
        Voter storage sender = voters[msg.sender];
        require(sender.weight > 0, "No right to vote.");
        require(!sender.voted, "Already voted.");
        // 进行投票
        sender.voted = true;
        sender.vote = proposal_id;
        proposals[proposal_id].voteCount += sender.weight;
    }

    /// @dev 结算票数，返回获胜提案的序号
    function winningProposal() public view returns (uint256 winningProposal_) {
        uint256 winningVoteCount = 0;
        for (uint256 p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    // 查询获胜提案的名称
    function winnerName() external view returns (bytes32 winnerName_) {
        winnerName_ = proposals[winningProposal()].name;
    }
}