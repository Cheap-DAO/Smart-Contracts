// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/governance/utils/IVotes.sol";
import "./IGovernor.sol";
import "./tunnel/FxBaseChildTunnel.sol";

contract Governor is FxBaseChildTunnel, IGovernor {
    struct Proposal {
        uint256 id;
        uint256 votingStart;
        uint256 votingEnd;
        bool canceled;
        bool infoSent;
    }

    enum VoteType {
        Against,
        For,
        Abstain
    }

    enum MessageType {
        ProposalCreated
    }

    struct ProposalVote {
        uint256 againstVotes;
        uint256 forVotes;
        uint256 abstainVotes;
        mapping(address => bool) hasVoted;
    }

    mapping(uint256 => ProposalVote) private _proposalVotes;

    mapping(uint256 => Proposal) public proposals;

    uint256 public totalProposals;
    uint256 private _quorumNumerator = 4;
    IVotes token;

    string private _name;

    constructor(
        string memory name_,
        IVotes _token,
        address _fxChild
    ) FxBaseChildTunnel(_fxChild) {
        token = _token;
        _name = name_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IGovernor-version}.
     */
    function version() public view virtual override returns (string memory) {
        return "1";
    }

    function votingDelay() public pure override returns (uint256) {
        return 1; // 1 block
    }

    function votingPeriod() public pure override returns (uint256) {
        return 5000;
    }

    function _processMessageFromRoot(
        uint256, /* stateId */
        address sender,
        bytes memory message
    ) internal override validateSender(sender) {
        (MessageType messageType, uint256 proposalId) = abi.decode(
            message,
            (MessageType, uint256)
        );
        if (messageType == MessageType.ProposalCreated) {
            _createProposal(proposalId);
        }
    }

    function _createProposal(uint256 id) internal {
        uint256 startBlock = block.number + votingDelay();
        uint256 endBlock = startBlock + votingPeriod();
        proposals[id] = Proposal({
            id: id,
            votingStart: startBlock,
            votingEnd: endBlock,
            canceled: false,
            infoSent: false
        });
        emit ProposalScheduled(id, startBlock, endBlock);
    }

    /**
     * @dev Returns the current quorum numerator. See {quorumDenominator}.
     */
    function setQuorumNumerator(uint256 _newQuorumNumerator) public {
        _quorumNumerator = _newQuorumNumerator;
    }

    /**
     * @dev Returns the current quorum numerator. See {quorumDenominator}.
     */
    function quorumNumerator() public view virtual returns (uint256) {
        return _quorumNumerator;
    }

    /**
     * @dev Returns the quorum denominator. Defaults to 100, but may be overridden.
     */
    function quorumDenominator() public view virtual returns (uint256) {
        return 100;
    }

    /**
     * @dev Returns the quorum for a block number, in terms of number of votes: `supply * numerator / denominator`.
     */
    function quorum(uint256 blockNumber)
        public
        view
        override
        returns (uint256)
    {
        return
            (token.getPastTotalSupply(blockNumber) * quorumNumerator()) /
            quorumDenominator();
    }

    function proposalSnapshot(uint256 proposalId)
        public
        view
        override
        returns (uint256)
    {
        return proposals[proposalId].votingStart;
    }

    function _quorumReached(uint256 proposalId) internal view returns (bool) {
        ProposalVote storage proposalvote = _proposalVotes[proposalId];

        return
            quorum(proposalSnapshot(proposalId)) <=
            proposalvote.forVotes + proposalvote.abstainVotes;
    }

    function _voteSucceeded(uint256 proposalId) internal view returns (bool) {
        ProposalVote storage proposalvote = _proposalVotes[proposalId];

        return proposalvote.forVotes > proposalvote.againstVotes;
    }

    function state(uint256 proposalId)
        public
        view
        override
        returns (ProposalState)
    {
        Proposal storage proposal = proposals[proposalId];

        if (proposal.infoSent) {
            return ProposalState.Transferred;
        }

        if (proposal.canceled) {
            return ProposalState.Canceled;
        }

        if (proposal.votingStart == 0) {
            revert("Governor: unknown proposal id");
        }

        if (proposal.votingStart >= block.number) {
            return ProposalState.Pending;
        }

        if (proposal.votingEnd >= block.number) {
            return ProposalState.Active;
        }

        if (_quorumReached(proposalId) && _voteSucceeded(proposalId)) {
            return ProposalState.Succeeded;
        } else {
            return ProposalState.Defeated;
        }
    }

    function hasVoted(uint256 proposalId, address account)
        public
        view
        override
        returns (bool)
    {
        return _proposalVotes[proposalId].hasVoted[account];
    }

    function proposalVotes(uint256 proposalId)
        public
        view
        returns (
            uint256 againstVotes,
            uint256 forVotes,
            uint256 abstainVotes
        )
    {
        ProposalVote storage proposalvote = _proposalVotes[proposalId];
        return (
            proposalvote.againstVotes,
            proposalvote.forVotes,
            proposalvote.abstainVotes
        );
    }

    function execute(uint256 id) public override {
        require(
            state(id) == ProposalState.Succeeded,
            "Proposal state is not succeeded"
        );
        Proposal storage proposal = proposals[id];
        proposal.infoSent = true;
        bytes memory message = abi.encode(id);
        _sendMessageToRoot(message);
    }

    function castVote(uint256 proposalId, uint8 support)
        public
        virtual
        override
        returns (uint256)
    {
        address voter = msg.sender;
        return _castVote(proposalId, voter, support, "");
    }

    function castVoteWithReason(
        uint256 proposalId,
        uint8 support,
        string memory reason
    ) public virtual override returns (uint256) {
        address voter = msg.sender;
        return _castVote(proposalId, voter, support, reason);
    }

    function castVoteWithReasonAndParams(
        uint256 proposalId,
        uint8 support,
        string calldata reason,
        bytes memory params
    ) public virtual override returns (uint256 balance) {
        address voter = msg.sender;
        return _castVote(proposalId, voter, support, reason, params);
    }

    function _castVote(
        uint256 proposalId,
        address account,
        uint8 support,
        string memory reason
    ) internal virtual returns (uint256) {
        return _castVote(proposalId, account, support, reason, "");
    }

    function _castVote(
        uint256 proposalId,
        address account,
        uint8 support,
        string memory reason,
        bytes memory params
    ) internal virtual returns (uint256) {
        Proposal storage proposal = proposals[proposalId];
        require(
            state(proposalId) == ProposalState.Active,
            "Governor: vote not currently active"
        );

        uint256 weight = _getVotes(account, proposal.votingStart, params);
        _countVote(proposalId, account, support, weight, params);

        if (params.length == 0) {
            emit VoteCast(account, proposalId, support, weight, reason);
        } else {
            emit VoteCastWithParams(
                account,
                proposalId,
                support,
                weight,
                reason,
                params
            );
        }

        return weight;
    }

    function getVotesWithParams(
        address account,
        uint256 blockNumber,
        bytes memory params
    ) public view virtual override returns (uint256) {
        return _getVotes(account, blockNumber, params);
    }

    function getVotes(address account, uint256 blockNumber)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _getVotes(account, blockNumber, "");
    }

    function _getVotes(
        address account,
        uint256 blockNumber,
        bytes memory /*params*/
    ) internal view virtual returns (uint256) {
        return token.getPastVotes(account, blockNumber);
    }

    function _countVote(
        uint256 proposalId,
        address account,
        uint8 support,
        uint256 weight,
        bytes memory // params
    ) internal virtual {
        ProposalVote storage proposalvote = _proposalVotes[proposalId];

        require(
            !proposalvote.hasVoted[account],
            "GovernorVotingSimple: vote already cast"
        );
        proposalvote.hasVoted[account] = true;

        if (support == uint8(VoteType.Against)) {
            proposalvote.againstVotes += weight;
        } else if (support == uint8(VoteType.For)) {
            proposalvote.forVotes += weight;
        } else if (support == uint8(VoteType.Abstain)) {
            proposalvote.abstainVotes += weight;
        } else {
            revert("GovernorVotingSimple: invalid value for enum VoteType");
        }
    }
}
