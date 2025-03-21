//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.19;

import "@forge-std/Test.sol";

import {Ownable} from "@openzeppelin-contracts/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

import {ProposalActions} from "@proposals/utils/ProposalActions.sol";
import {MOONBEAM_FORK_ID} from "@utils/ChainIds.sol";
import {HybridProposal, ActionType} from "@proposals/proposalTypes/HybridProposal.sol";
import {AllChainAddresses as Addresses} from "@proposals/Addresses.sol";

contract mipm42 is HybridProposal {
    using ProposalActions for *;

    string public constant override name = "MIP-M42";

    constructor() {
        bytes memory proposalDescription = abi.encodePacked(
            vm.readFile("./proposals/mips/mip-m42/MIP-M42.md")
        );
        _setProposalDescription(proposalDescription);
    }

    function primaryForkId() public pure override returns (uint256) {
        return MOONBEAM_FORK_ID;
    }

    function deploy(Addresses addresses, address) public override {
        if (!addresses.isAddressSet("API3_GLMR_USD_OEV_FEED")) {
            addresses.addAddress(
                string(abi.encodePacked("API3_GLMR_USD_OEV_FEED")),
                address(0x80308dCE5bd550209FDb22871ce411869014EE8E)
            );
        }
    }

    function build(Addresses addresses) public override {
        _pushAction(
            addresses.getAddress("CHAINLINK_ORACLE"),
            abi.encodeWithSignature(
                "setFeed(string,address)",
                ERC20(addresses.getAddress("mGLMR")).symbol(),
                addresses.getAddress("API3_GLMR_USD_OEV_FEED")
            ),
            "Set price feed for WETH"
        );
    }

    function validate(Addresses addresses, address) public override {
        vm.selectFork(primaryForkId());
    }
}
