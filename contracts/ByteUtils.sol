// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.6;

library ByteUtils {
    function equals(bytes memory _a, bytes memory _b)
        public
        pure
        returns (bool)
    {
        if (_a.length != _b.length) return false;
        for (uint256 i = 0; i < _a.length; i++)
            if (_a[i] != _b[i]) return false;
        return true;
    }
}
