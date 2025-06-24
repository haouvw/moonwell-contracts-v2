// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.19;

import {HybridProposal} from "@proposals/proposalTypes/HybridProposal.sol";
import {Configs} from "@proposals/Configs.sol";
import {BASE_FORK_ID, OPTIMISM_FORK_ID} from "@utils/ChainIds.sol";
import {AllChainAddresses as Addresses} from "@proposals/Addresses.sol";
import {Comptroller} from "@protocol/Comptroller.sol";


// this proposal should call Comptroller._setBorrowCapGuardian and Comptroller._setSupplyCapGuardian on both Base and Optimism
contract x24 is HybridProposal, Configs {
    string public constant override name = "MIP-X24";

    constructor() {
        _setProposalDescription(
            bytes(vm.readFile("./proposals/mips/mip-x24/MIP-X24.md"))
        );

    }

function primaryForkId() public pure override returns (uint256) {
        return BASE_FORK_ID;
    }

    function build(Addresses addresses) public override {
        
        vm.selectFork(BASE_FORK_ID);
        _pushAction(
            addresses.getAddress("UNITROLLER"),
            abi.encodeWithSignature(
                "setBorrowCapGuardian(address)",
                addresses.getAddress("ANTHIAS_MULTISIG")
            ),

            "Set borrow cap guardian on Base"
        );

        _pushAction(
            addresses.getAddress("UNITROLLER"),
            abi.encodeWithSignature(
                "setSupplyCapGuardian(address)",
                addresses.getAddress("ANTHIAS_MULTISIG")
            ),
            "Set supply cap guardian on Base"
        );

        vm.selectFork(OPTIMISM_FORK_ID);

        _pushAction(
            addresses.getAddress("UNITROLLER"),
            abi.encodeWithSignature(
                "setBorrowCapGuardian(address)",
                addresses.getAddress("ANTHIAS_MULTISIG")
            ),
            "Set borrow cap guardian on Optimism"
        );

        _pushAction(
            addresses.getAddress("UNITROLLER"),
            abi.encodeWithSignature(
                "setSupplyCapGuardian(address)",
                addresses.getAddress("ANTHIAS_MULTISIG")
            ),
            "Set supply cap guardian on Optimism"
        );
    }

    function validate(Addresses addresses, address) public override {
        vm.selectFork(BASE_FORK_ID);
        address guardian = addresses.getAddress("ANTHIAS_MULTISIG");
        Comptroller unitroller = Comptroller(addresses.getAddress("UNITROLLER"));
        
        assertEq(unitroller.borrowCapGuardian(), guardian, "Borrow cap guardian on Base is not set");
        assertEq(unitroller.supplyCapGuardian(), guardian, "Supply cap guardian on Base is not set");

        vm.selectFork(OPTIMISM_FORK_ID);
        assertEq(unitroller.borrowCapGuardian(), guardian, "Borrow cap guardian on Optimism is not set");
        assertEq(unitroller.supplyCapGuardian(), guardian, "Supply cap guardian on Optimism is not set");


    }   
}