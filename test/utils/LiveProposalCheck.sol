// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.19;

import "@forge-std/Test.sol";

import {console} from "@forge-std/console.sol";

import "@utils/ChainIds.sol";
import {Bytes} from "@utils/Bytes.sol";
import {xWELL} from "@protocol/xWELL/xWELL.sol";
import {String} from "@utils/String.sol";
import {Address} from "@utils/Address.sol";
import {Proposal} from "@proposals/Proposal.sol";
import {Networks} from "@proposals/utils/Networks.sol";
import {IWormhole} from "@protocol/wormhole/IWormhole.sol";
import {ProposalMap} from "@test/utils/ProposalMap.sol";
import {ProposalView} from "@protocol/views/ProposalView.sol";
import {Implementation} from "@test/mock/wormhole/Implementation.sol";
import {ProposalAction} from "@proposals/proposalTypes/IProposal.sol";
import {ProposalActions} from "@proposals/utils/ProposalActions.sol";
import {ProposalChecker} from "@proposals/utils/ProposalChecker.sol";
import {TemporalGovernor} from "@protocol/governance/TemporalGovernor.sol";
import {WormholeBridgeAdapter} from "@protocol/xWELL/WormholeBridgeAdapter.sol";
import {WormholeRelayerAdapter} from "@test/mock/WormholeRelayerAdapter.sol";
import {HybridProposal, ActionType} from "@proposals/proposalTypes/HybridProposal.sol";
import {AllChainAddresses as Addresses} from "@proposals/Addresses.sol";
import {IMultichainGovernor, MultichainGovernor} from "@protocol/governance/multichain/MultichainGovernor.sol";

contract LiveProposalCheck is Test, ProposalChecker, Networks {
    using String for string;
    using Address for *;
    using Bytes for bytes;
    using ChainIds for uint256;
    using ProposalActions for *;

    /// @notice proposal to file map contract
    ProposalMap proposalMap;

    /// @notice allows asserting wormhole core correctly emits data to temporal governor
    event LogMessagePublished(
        address indexed sender,
        uint64 sequence,
        uint32 nonce,
        bytes payload,
        uint8 consistencyLevel
    );

    function setUp() public virtual {
        proposalMap = new ProposalMap();
        vm.makePersistent(address(proposalMap));
    }

    function executeSucceededProposals(
        Addresses addresses,
        MultichainGovernor governor
    ) public {
        if (vm.activeFork() != MOONBEAM_FORK_ID) {
            vm.selectFork(MOONBEAM_FORK_ID);
        }

        uint256 proposalId = governor.proposalCount();

        mockWell(addresses, governor);

        uint256 count = 0;

        while (count < 10) {
            // TODO remove this once we have the ability to cancel proposals
            if (proposalId != 90) {
                IMultichainGovernor.ProposalState state = governor.state(
                    proposalId
                );

                if (state == IMultichainGovernor.ProposalState.Succeeded) {
                    _execProposal(addresses, governor, proposalId);
                }
            }

            proposalId--;
            count++;
        }
    }

    function executeTemporalGovernorQueuedProposals(
        Addresses addresses,
        MultichainGovernor governor
    ) public {
        if (vm.activeFork() != MOONBEAM_FORK_ID) {
            vm.selectFork(MOONBEAM_FORK_ID);
        }

        uint256 proposalId = governor.proposalCount();
        for (uint256 i = 0; i < networks.length; i++) {
            uint256 chainId = networks[i].chainId;

            // skip moonbeam
            if (chainId == block.chainid.toMoonbeamChainId()) {
                continue;
            }

            vm.selectFork(chainId.toForkId());
            ProposalView proposalView = ProposalView(
                addresses.getAddress("PROPOSAL_VIEW")
            );

            uint256 proposalStart = proposalId;
            uint256 count = 0;

            while (count < 10) {
                if (
                    proposalView.proposalStates(proposalStart) ==
                    ProposalView.ProposalState.Queued
                ) {
                    (
                        string memory proposalPath,
                        string memory envPath
                    ) = proposalMap.getProposalById(proposalStart);

                    if (
                        keccak256(abi.encodePacked(proposalPath)) ==
                        keccak256(abi.encodePacked(""))
                    ) {
                        proposalId--;
                        count++;
                        continue;
                    }

                    proposalMap.setEnv(envPath);
                    HybridProposal proposal = HybridProposal(
                        deployCode(proposalPath)
                    );
                    vm.makePersistent(address(proposal));

                    vm.selectFork(proposal.primaryForkId());

                    proposal.initProposal(addresses);
                    proposal.build(addresses);

                    ProposalAction[] memory actions = proposal.getActionsByType(
                        ActionType(chainId.toForkId())
                    );

                    if (actions.length == 0) {
                        proposalId--;
                        count++;
                        continue;
                    }

                    bytes memory temporalGovCalldata = proposal
                        .getTemporalGovCalldata(
                            addresses.getAddress("TEMPORAL_GOVERNOR", chainId),
                            actions
                        );

                    (, bytes memory payload, ) = abi.decode(
                        /// 1. strip off function selector
                        /// 2. decode the call to publishMessage payload
                        temporalGovCalldata.slice(
                            4,
                            temporalGovCalldata.length - 4
                        ),
                        (uint32, bytes, uint8)
                    );

                    _execExtChain(addresses, governor, payload, proposalStart);
                }
                proposalStart--;
                count++;
            }
        }

        if (vm.activeFork() != MOONBEAM_FORK_ID) {
            vm.selectFork(MOONBEAM_FORK_ID);
        }
    }

    function executeLiveProposals(
        Addresses addresses,
        MultichainGovernor governor
    ) public {
        if (vm.activeFork() != MOONBEAM_FORK_ID) {
            vm.selectFork(MOONBEAM_FORK_ID);
        }

        uint256[] memory liveProposals = governor.liveProposals();

        mockWell(addresses, governor);

        for (uint256 i = 0; i < liveProposals.length; i++) {
            _execProposal(addresses, governor, liveProposals[i]);
        }
    }

    function _execProposal(
        Addresses addresses,
        MultichainGovernor governor,
        uint256 proposalId
    ) public {
        /// add restriction for moonbeam actions
        addresses.addRestriction(block.chainid.toMoonbeamChainId());

        (
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory calldatas
        ) = governor.getProposalData(proposalId);

        checkMoonbeamActions(targets);
        {
            // Simulate proposals execution
            (
                ,
                ,
                uint256 votingStartTime,
                ,
                uint256 crossChainVoteCollectionEndTimestamp,
                ,
                ,
                ,

            ) = governor.proposalInformation(proposalId);

            vm.warp(votingStartTime);

            governor.castVote(proposalId, 0);

            vm.warp(crossChainVoteCollectionEndTimestamp + 1);
        }

        uint256 totalValue = 0;

        for (uint256 j = 0; j < values.length; j++) {
            totalValue += values[j];
        }

        vm.deal(address(this), totalValue);

        bytes memory payload;

        address wormholeCore = addresses.getAddress("WORMHOLE_CORE");

        /// remove restriction for moonbeam actions
        addresses.removeRestriction();

        (string memory proposalPath, string memory envPath) = proposalMap
            .getProposalById(proposalId);

        if (
            keccak256(abi.encodePacked(proposalPath)) ==
            keccak256(abi.encodePacked(""))
        ) {
            return;
        }

        proposalMap.setEnv(envPath);

        Proposal proposal = Proposal(deployCode(proposalPath));
        proposal.beforeSimulationHook(addresses);

        uint64 nextSequence = IWormhole(wormholeCore).nextSequence(
            address(governor)
        );

        for (uint256 i = 0; i < targets.length; i++) {
            if (targets[i] == wormholeCore) {
                // decode temporal governor calldata
                (, payload, ) = abi.decode(
                    /// 1. strip off function selector
                    /// 2. decode the call to publishMessage payload
                    calldatas[i].slice(4, calldatas[i].length - 4),
                    (uint32, bytes, uint8)
                );

                /// increments each time the Multichain Governor publishes a message
                vm.expectEmit(true, true, true, true, wormholeCore);

                emit LogMessagePublished(
                    address(governor),
                    nextSequence++,
                    0,
                    payload,
                    200
                );
            }
        }

        governor.execute{value: totalValue}(proposalId);

        {
            /// supports as many destination networks as needed
            uint256 j = targets.length;

            /// iterate over all targets to check if any of them is the wormhole core
            /// if the target is WormholeCore, run the Temporal Governor logic on the corresponding chain
            while (j != 0) {
                if (targets[j - 1] == wormholeCore) {
                    console.log(
                        "Executing Temporal Governor for proposal %i: ",
                        proposalId
                    );

                    // decode temporal governor calldata
                    (, payload, ) = abi.decode(
                        /// 1. strip off function selector
                        /// 2. decode the call to publishMessage payload
                        calldatas[j - 1].slice(4, calldatas[j - 1].length - 4),
                        (uint32, bytes, uint8)
                    );

                    _execExtChain(addresses, governor, payload, proposalId);
                }

                j--;
            }
        }

        if (vm.activeFork() != MOONBEAM_FORK_ID) {
            vm.selectFork(MOONBEAM_FORK_ID);
        }

        proposal.afterSimulationHook(addresses);
    }

    function _execExtChain(
        Addresses addresses,
        MultichainGovernor governor,
        bytes memory payload,
        uint256 proposalId
    ) private {
        (
            address temporalGovernorAddress,
            address[] memory baseTargets,
            ,

        ) = abi.decode(payload, (address, address[], uint256[], bytes[]));

        vm.selectFork(BASE_FORK_ID);
        // check if the Temporal Governor address exist on the base chain
        if (address(temporalGovernorAddress).code.length == 0) {
            // if not, checkout to Optimism fork id
            vm.selectFork(OPTIMISM_FORK_ID);
        }

        address expectedTemporalGov = addresses.getAddress("TEMPORAL_GOVERNOR");

        require(
            temporalGovernorAddress == expectedTemporalGov,
            "Temporal Governor address mismatch"
        );

        checkBaseOptimismActions(baseTargets);

        bytes memory vaa = generateVAA(
            uint32(block.timestamp),
            block.chainid.toMoonbeamWormholeChainId(),
            address(governor).toBytes(),
            payload
        );

        TemporalGovernor temporalGovernor = TemporalGovernor(
            payable(expectedTemporalGov)
        );

        {
            // Deploy the modified Wormhole Core implementation contract which
            // bypass the guardians signature check
            Implementation core = new Implementation();
            address wormhole = addresses.getAddress(
                "WORMHOLE_CORE",
                block.chainid
            );

            /// Set the wormhole core address to have the
            /// runtime bytecode of the mock core
            vm.etch(wormhole, address(core).code);
        }

        temporalGovernor.queueProposal(vaa);

        vm.warp(block.timestamp + temporalGovernor.proposalDelay());

        try temporalGovernor.executeProposal(vaa) {} catch (bytes memory e) {
            console.log(
                string(
                    abi.encodePacked(
                        "Error executing proposal, error: ",
                        string(e)
                    )
                )
            );

            (string memory proposalPath, string memory envPath) = proposalMap
                .getProposalById(proposalId);

            if (
                keccak256(abi.encodePacked(proposalPath)) ==
                keccak256(abi.encodePacked(""))
            ) {
                return;
            }

            proposalMap.setEnv(envPath);

            Proposal proposal = Proposal(deployCode(proposalPath));

            proposal.initProposal(addresses);
            proposal.beforeSimulationHook(addresses);

            temporalGovernor.executeProposal(vaa);

            proposal.afterSimulationHook(addresses);
        }
    }

    /// @dev utility function to generate a Wormhole VAA payload excluding the guardians signature
    function generateVAA(
        uint32 timestamp,
        uint16 emitterChainId,
        bytes32 emitterAddress,
        bytes memory payload
    ) private pure returns (bytes memory encodedVM) {
        uint64 sequence = 200;
        uint8 version = 1;
        uint32 nonce = 0;
        uint8 consistencyLevel = 200;

        encodedVM = abi.encodePacked(
            version,
            timestamp,
            nonce,
            emitterChainId,
            emitterAddress,
            sequence,
            consistencyLevel,
            payload
        );
    }

    function mockWell(Addresses addresses, MultichainGovernor governor) public {
        uint256 timestampBefore = vm.getBlockTimestamp();

        address well = addresses.getAddress("xWELL_PROXY");

        vm.warp(1000);

        deal(well, address(this), governor.quorum());
        xWELL(well).delegate(address(this));

        vm.warp(timestampBefore);
    }
}
