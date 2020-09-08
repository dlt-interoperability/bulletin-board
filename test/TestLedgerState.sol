pragma solidity >0.7.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/MetaCoin.sol";

contract TestLedgerState {
    function testSettingOfAdmin() public {
        PermissionedState meta = PermissionedState(
            DeployedAddresses.PermissionedState()
        );
        Assert.equal(
            meta.getAdmin(),
            tx.origin,
            "The admin should be the entity that initiates this contract"
        );
    }
}
