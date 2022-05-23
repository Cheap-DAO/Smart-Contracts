// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./tunnel/FxBaseRootTunnel.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract Treasury is FxBaseRootTunnel {
    struct Proposal {
        uint256 id;
        address[] targets;
        uint256[] values;
        bytes[] calldatas;
        bytes32 descriptionHash;
        bool executed;
    }

    enum MessageType {
        ProposalCreated
    }

    mapping(uint256 => Proposal) public proposals;

    uint256 public totalProposals;

    event ProposalCreated(
        uint256 proposalId,
        address proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        string description
    );

    constructor(address _checkpointManager, address _fxRoot)
        FxBaseRootTunnel(_checkpointManager, _fxRoot)
    {}

    function _processMessageFromChild(bytes calldata data) internal override {
        uint256 id = abi.decode(data, (uint256));
        execute(id);
    }

    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public {
        uint256 id = totalProposals++;
        proposals[id] = Proposal({
            id: id,
            targets: targets,
            values: values,
            calldatas: calldatas,
            descriptionHash: keccak256(bytes(description)),
            executed: false
        });
        bytes memory message = abi.encode(MessageType.ProposalCreated, id);
        _sendMessageToChild(message);
        emit ProposalCreated(
            id,
            msg.sender,
            targets,
            values,
            new string[](targets.length),
            calldatas,
            description
        );
    }

    function execute(uint256 id) internal {
        Proposal storage proposal = proposals[id];
        require(!proposal.executed, "proposal already executed");
        proposal.executed = true;
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            (bool success, bytes memory returndata) = proposal.targets[i].call{
                value: proposal.values[i]
            }(proposal.calldatas[i]);
            Address.verifyCallResult(
                success,
                returndata,
                "Governer: call reverted without message"
            );
        }
    }
    // function sendMessageToChild(bytes memory message) public {
    //     _sendMessageToChild(message);
    // }
}
