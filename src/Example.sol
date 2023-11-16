// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract MagicDispatch {
    // a magic number to modulo the selector by to get a unique index [0,16)
    uint256 constant MAGIC_MOD = 0x2a999;
    // table of up to 16 different jumpdests; should be in same order as selectors
    uint256 constant MAGIC_JUMPDEST = 0x000100020003000400050006000700080009000a000b000c000d000e000f;
    // (note: these selectors are not ordered according to magic mod)
    // table of up to 8 different 4-byte selectors
    uint256 constant BIN_ZERO = 0x06fdde0346423aa75b34b96679df72bd87201b4188147732a8174404a900866b;
    // table of up to 8 different 4-byte selectors
    uint256 constant BIN_ONE = 0xb3a34c4ce7acab24ed98a574f07ec373f2d12b12f47b7740fb0f3ee100000000;

    uint256 constant _32_BIT_MASK = 0xffffffff;
    uint256 constant _16_BIT_MASK = 0xffff;
    uint256 constant INVALID_SELECTOR_ERROR_SELECTOR = 0x7352d91c;

    fallback() external payable {
        function() internal dest_func;
        assembly {
            let selector := shr(224, calldataload(0))
            // modulo by magic_mod to get unique index [0,16)
            let magic_mod := mod(selector, MAGIC_MOD)
            // get the index within a 32-byte bin
            let bin_index := and(magic_mod, 7)
            // calculate amount to right-shift bin by
            let shift_amount := sub(224, shl(5, bin_index))
            // put only the relevant bin on the stack; if greater than 7, belongs in bin 1
            let bin_number := gt(magic_mod, 7)
            let bin := or(mul(bin_number, BIN_ZERO), mul(iszero(bin_number), BIN_ONE))
            // shift and mask the bin
            let shifted_masked_bin := and(_32_BIT_MASK, shr(shift_amount, bin))
            // compare the shifted and masked bin to the selector
            let check := eq(shifted_masked_bin, selector)
            // fail fast if the selector does not match what is in the bin
            // returndatacopy(returndatasize(), returndatasize(), iszero(check))
            if iszero(check) {
                mstore(0, INVALID_SELECTOR_ERROR_SELECTOR)
                revert(0x1c, 4)
            }

            // now that selector is validated, shift and mask the destination from the jumpdest table
            shift_amount := sub(240, shl(4, magic_mod))
            dest_func := and(_16_BIT_MASK, shr(shift_amount, MAGIC_JUMPDEST))
        }
        // dest_func();
    }
}
