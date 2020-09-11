// SPDX-License-Identifier: MIT
pragma solidity >0.4;
pragma experimental ABIEncoderV2;
import "./StringUtils.sol";

contract LedgerState {
    struct StateCommitment {
        bytes32 value;
        uint256 height;
        bool ratified;
        bool disputed;
        uint256 votesTally;
    }

    struct Policy {
        uint256 quorum;
    }

    event CommitmentProposed(
        bytes32 indexed commitment,
        string member,
        bytes32 signature,
        uint256 indexed height
    );

    event VoteReceived(
        bytes32 indexed commitment,
        string member,
        bytes32 signature,
        uint256 indexed heightt
    );

    event CommitmentRatified(
        bytes32 indexed commitment,
        uint256 indexed height,
        uint256 voteTally
    );

    event CommitmentConflictDetected(
        uint256 indexed height,
        bytes32 assumedComm,
        bytes32 conflictingComm,
        bytes32 signature,
        string member
    );

    mapping(address => string) committee;
    mapping(uint256 => StateCommitment) commitments;
    mapping(uint256 => address) committeeIndex;
    uint256 committeeSize;

    Policy policy;
    uint256 currComm;
    uint256 candComm;
    address admin;

    constructor() public {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only an admin can update the committee");
        _;
    }

    modifier onlyCommitteeMembers() {
        require(
            !isEmpty(committee[msg.sender]),
            "voter is not a known committee member"
        );
        _;
    }

    function setManagementCommittee(
        address[] calldata memEthAdds,
        string[] calldata memDLTPubKeys
    ) external onlyAdmin {
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
	@notice Get the latest ratified commitment
	@return the latest commitment and the ledger height for which it was computed
	*/
    function getCommitment() external view returns (bytes32, uint256) {
        return getCommitmentAt(currComm);
    }

    /**
	@notice Get commitment at a specific height
	@return the latest commitment and the ledger height for which it was computed
	*/
    function getCommitmentAt(uint256 height)
        public
        view
        returns (bytes32, uint256)
    {
        // TODO: return the status of the commitment: disputed, ratified
        return (commitments[height].value, commitments[currComm].height);
    }

    function getCandidateCommitment()
        external
        view
        returns (
            bytes32,
            uint256,
            uint256
        )
    {
        return (
            commitments[candComm].value,
            commitments[candComm].height,
            commitments[candComm].votesTally
        );
    }

    function checkCommitAllowed(uint256 _height) private view {
        require(committeeSize > 0, "there is not management committee set");

        require(
            policy.quorum > 0,
            "a policy for quorum size has not been configured yet"
        );

        require(
            _height > 0,
            "the ledger height for snapshop has to be greater than zero"
        );

        require(
            commitments[_height].disputed == false,
            "the commitment is currently disputed"
        );
    }

    function flagConflict(
        uint256 _height,
        bytes32 _comm,
        bytes32 _signature
    ) private {
        commitments[_height].disputed = true;

        emit CommitmentConflictDetected(
            _height,
            commitments[_height].value,
            _comm,
            _signature,
            committee[msg.sender]
        );
    }

    function reportConflictingCommitment(
        uint256 _height,
        bytes32 _comm,
        bytes32 _signature
    ) external onlyCommitteeMembers {
        checkCommitAllowed(_height);
        require(
            commitments[_height].value != _comm,
            "a conflicting commitment cannot be the same as the saved commitment"
        );
        flagConflict(_height, _comm, _signature);
    }

    function postCommitment(
        bytes32 _comm,
        bytes32 _signature,
        uint256 _height
    ) external onlyCommitteeMembers returns (bool) {
        //TODO prevent double voting scenario
        checkCommitAllowed(_height);

        require(
            _height > commitments[currComm].height &&
                _height >= commitments[candComm].height,
            "votes on already ratified commitments are not allowed"
        );

        if (_height == candComm) {
            if (_comm != commitments[candComm].value) {
                flagConflict(_height, _comm, _signature);
                return false;
            }
            commitments[candComm].votesTally += 1;
            if (commitments[candComm].votesTally >= policy.quorum) {
                commitments[candComm].ratified = true;
                emit CommitmentRatified(
                    _comm,
                    _height,
                    commitments[candComm].votesTally
                );
                currComm = candComm;
            }
            return true;
        }
        address[] memory votes = new address[](1);
        votes[0] = msg.sender;

        commitments[_height] = StateCommitment({
            value: _comm,
            height: _height,
            votesTally: 1,
            ratified: false,
            disputed: false
        });
        candComm = _height;
        return true;
    }

    /**
	@notice Assign the policy that governs operations of the contract.
	@param quorum the minimum number of nodes that need to vote to ratify a state commitment
	*/
    function setPolicy(uint256 quorum) external onlyAdmin {
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
