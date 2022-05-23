// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ICheckpointManager} from "../tunnel/FxBaseRootTunnel.sol";

contract TestCheckpointManager is ICheckpointManager {
    constructor() {}

    function addHeaderBlock(
        uint256 headerNumber,
        bytes32 root,
        uint256 start,
        uint256 end,
        uint256 createdAt,
        address proposer
    ) public {
        headerBlocks[headerNumber] = HeaderBlock(
            root,
            start,
            end,
            createdAt,
            proposer
        );
    }
}
