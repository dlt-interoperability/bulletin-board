// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.6;
pragma experimental ABIEncoderV2;
import "./StringUtils.sol";

/// @title Manage committee details
/// @notice Maintains details about the members of a management committee of a permissioned network.
contract ManagementCommittee {
    using StringUtils for string;
    mapping(address => string) committeeKeys;
    // this array is slightly redundant but is required because we cant iterate over a map
    address[] committeeList;

    // the only account that is able to change the committee
    address public admin;

    event ManagmentCommitteeUpdated();

    modifier onlyAdmin() {
        require(msg.sender == admin, "only an admin can update the committee");
        _;
    }

    constructor(address _admin) {
        admin = _admin;
    }

    /// @notice Set the complete list of members of a management committee.
    /// @param _memDltPubKeys the list of public keys of each member in the permissioned DLT network
    /// @param _memEthAdds the Ethereum address of the member identified in the corresponding index in memDLTPubKey e.g. _memEthAdds[i] would be address for _memDltPubKeys[i]
    function setCommittee(
        string[] calldata _memDltPubKeys,
        address[] calldata _memEthAdds
    ) external onlyAdmin {
        require(
            _memEthAdds.length == _memDltPubKeys.length,
            "There should be a matching DLT public key for every Ethereum address"
        );
        for (uint256 i = 0; i < _memEthAdds.length; i++) {
            committeeKeys[_memEthAdds[i]] = _memDltPubKeys[i];
        }
        committeeList = _memEthAdds;

        emit ManagmentCommitteeUpdated();
    }

    function getCommittee()
        external
        view
        returns (address[] memory, string[] memory)
    {
        string[] memory cPks = new string[](committeeList.length);
        for (uint256 i = 0; i < committeeList.length; i++) {
            address addr = committeeList[i];
            cPks[i] = committeeKeys[addr];
        }
        return (committeeList, cPks);
    }

    function getDLTPublicKeyFor(address member)
        public
        view
        returns (string memory)
    {
        return committeeKeys[member];
    }

    function getDLTPublicKey() public view returns (string memory) {
        return getDLTPublicKeyFor(msg.sender);
    }

    function getCommitteeSize() public view returns (uint256) {
        return committeeList.length;
    }

    function isMember(address _m) public view returns (bool) {
        return !committeeKeys[_m].isEmpty();
    }

    function hasMembers() public view returns (bool) {
        return committeeList.length > 0;
    }
}
