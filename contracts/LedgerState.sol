// SPDX-License-Identifier: MIT
pragma solidity >0.4;
pragma experimental ABIEncoderV2;
import "./StringUtils.sol";

contract LedgerState {
    struct StateCommittment {
        bytes32 value;
        uint256 height;
        bool ratified;
        uint256 votesTally;
    }

    struct Policy {
        uint256 quorum;
    }

    event CommittmentProposed(
        bytes32 indexed committment,
        string member,
        bytes32 signature,
        uint256 indexed height
    );

    event VoteReceived(
        bytes32 indexed committment,
        string member,
        bytes32 signature,
        uint256 indexed heightt
    );

    event CommittmentRatified(
        bytes32 indexed committment,
        uint256 indexed height
    );

    event CommittmentConflictDetected(
        uint256 indexed height,
        bytes32 assumedComm,
        bytes32 conflictingComm,
        bytes32 signature,
        string member
    );

    mapping(address => string) committee;
    mapping(uint256 => StateCommittment) committments;
    mapping(uint256 => address) committeeIndex;
    uint256 committeeSize;

    Policy policy;
    uint256 currComm;
    uint256 candComm;
    address admin;

    constructor() public {
        admin = msg.sender;
    }

    function setManagementCommittee(
        address[] calldata memEthAdds,
        string[] calldata memDLTPubKeys
    ) external {
        require(msg.sender == admin, "only an admin can update the committee");
        require(
            memEthAdds.length == memDLTPubKeys.length,
            "For each member in the committe there should be an Ethereum address and a corresponding public key in the permissioned DLT"
        );
        committeeSize = memEthAdds.length;
        for (uint256 i = 0; i < memEthAdds.length; i++) {
            committee[memEthAdds[i]] = memDLTPubKeys[i];
            committeeIndex[i] = memEthAdds[i];
        }
        // TODO: emit an event when this happens
    }

    function getManagementCommittee()
        external
        view
        returns (address[] memory, string[] memory)
    {
        address[] memory adds = new address[](committeeSize);
        string[] memory pks = new string[](committeeSize);
        for (uint256 i = 0; i < committeeSize; i++) {
            address addr = committeeIndex[i];
            adds[i] = addr;
            pks[i] = committee[addr];
        }
        return (adds, pks);
    }

    function getCommitteeMemberDLTPubKey() public view returns (string memory) {
        return committee[msg.sender];
    }

    /**
	@notice Get the latest ratified committment
	@return the latest committment and the ledger height for which it was computed
	*/
    function getCommittment() external view returns (bytes32, uint256) {
        return (committments[currComm].value, committments[currComm].height);
    }

    function getCandidateCommittment()
        external
        view
        returns (bytes32, uint256)
    {
        return (committments[candComm].value, committments[candComm].height);
    }

    function postCommittment(
        bytes32 _comm,
        bytes32 _signature,
        uint256 _height
    ) external returns (bool) {
        require(committeeSize > 0, "there is not management committee set");

        require(
            policy.quorum > 0,
            "a policy for quorum size has not been configured yet"
        );

        require(
            !isEmpty(committee[msg.sender]),
            "voter is not a known committee member"
        );

        require(
            _height > 0,
            "the ledger height for snapshop has to be greater than zero"
        );

        require(
            _height > committments[currComm].height &&
                _height > committments[candComm].height,
            "votes on already ratified committments are not allowed"
        );

        if (_height == candComm) {
            if (_comm == committments[candComm].value) {
                emit CommittmentConflictDetected(
                    _height,
                    committments[candComm].value,
                    _comm,
                    _signature,
                    committee[msg.sender]
                );
                return false;
            }
            committments[candComm].votesTally += 1;
            if (committments[candComm].votesTally >= policy.quorum) {
                committments[candComm].ratified = true;
                emit CommittmentRatified(_comm, _height);
            }
        } else {
            committments[_height] = StateCommittment({
                value: _comm,
                height: _height,
                votesTally: 1,
                ratified: false
            });
            candComm = _height;
            return true;
        }
    }

    /**
	@notice Assign the policy that governs operations of the contract.
	@param quorum the minimum number of nodes that need to vote to ratify a state committment
	*/
    function setPolicy(uint256 quorum) external {
        require(msg.sender == admin, "only the admin can update policy");
        require(quorum > 0, "quorum size cannot be zero");
        policy = Policy({quorum: quorum});
        // TODO: emit an event
    }

    function getPolicy() public view returns (uint256) {
        return policy.quorum;
    }

    function getAdmin() public view returns (address) {
        return admin;
    }

    function isEmpty(string memory str) private pure returns (bool) {
        return StringUtils.equal(str, "");
    }
}
