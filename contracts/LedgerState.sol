// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.6;
pragma experimental ABIEncoderV2;
import "./ManagementCommittee.sol";

contract LedgerState {
    enum Status {PROPOSED, RATIFIED, REPLACED, DISPUTED}

    struct StateCommitment {
        bytes32 value;
        bytes32 rollingHash;
        uint256 atHeight;
        Status status;
        Vote[] votes;
    }

    struct Vote {
        address member;
    }

    struct Policy {
        uint256 quorum;
    }

    event CommitmentProposed(
        bytes32 indexed commitment,
        string member,
        uint256 indexed atHeight
    );
    event CommitmentRatified(
        bytes32 indexed commitment,
        uint256 indexed atHeight,
        uint256 voteTally
    );

    event CommitmentReplaced(
        uint256 indexed oldLedgerHeight,
        uint256 indexed newLedgerHeight
    );

    event CommitmentConflictDetected(
        uint256 indexed atHeight,
        bytes32 assumedComm,
        bytes32 conflictingComm,
        string member
    );

    event VoteReceived(
        uint256 indexed height
    );

    event PolicyUpdated(
        uint256 quorum
    );

    mapping(uint256 => StateCommitment) commitments;

    // the height of the current ratified commitment
    uint256 currentHeight;

    // the height of the proposed candidate commitment.
    // this is a proposed commitment awaiting enough votes to be ratified.
    // once it received enough votes it transitions into a "current" state,
    // unless superceded by a more recent commitment or its validity is disputed.
    uint256 candidateHeight;

    // the only account that is able to update policy or the management committee
    address public admin;
    // the policy that governs how commitments are ratified. currently this is a simple threshold based voting mechanism
    Policy policy;

    ManagementCommittee public committee;

    constructor() {
        admin = msg.sender;
        committee = new ManagementCommittee(admin);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only an admin can update the committee");
        _;
    }

    modifier onlyCommitteeMembers() {
        require(
            committee.isMember(msg.sender),
            "voter is not a known committee member"
        );
        _;
    }

    modifier validCommitPreconditions(uint256 _height) {
        require(
            committee.hasMembers(),
            "there is not management committee set"
        );

        require(
            policy.quorum > 0,
            "a policy for quorum size has not been configured yet"
        );

        require(
            _height > 0,
            "the ledger atHeight for snapshop has to be greater than zero"
        );

        require(
            commitments[_height].status != Status.DISPUTED,
            "the commitment is currently disputed"
        );

        _;
    }

    /**
	@notice Get the latest ratified commitment
	@return the latest ratified commitment and and the ledger height for which it was computed
	*/
    function getCommitment()
        external
        view
        returns (
            bytes32,
            Status,
            uint256
        )
    {
        (bytes32 value, Status status) = getCommitmentAt(currentHeight);
        return (value, status, currentHeight);
    }

    /**
	@notice Get commitment at a specified ledger height, regardless of the state of the commitment.
	@return the commitment at the specified height
	*/
    function getCommitmentAt(uint256 atHeight)
        public
        view
        returns (bytes32, Status)
    {
        StateCommitment memory c = commitments[atHeight];
        return (c.value, c.status);
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
            commitments[candidateHeight].value,
            commitments[candidateHeight].atHeight,
            commitments[candidateHeight].votes.length
        );
    }

    function flagConflict(
        uint256 _height,
        bytes32 _comm
    ) private {
        commitments[_height].status = Status.DISPUTED;

        emit CommitmentConflictDetected(
            _height,
            commitments[_height].value,
            _comm,
            committee.getDLTPublicKeyFor(msg.sender)
        );
    }

    function reportConflictingCommitment(
        uint256 _height,
        bytes32 _comm
    ) external onlyCommitteeMembers validCommitPreconditions(_height) {
        require(
            commitments[_height].value != _comm,
            "a conflicting commitment cannot be the same as the saved commitment"
        );
        flagConflict(_height, _comm);
    }

    function postCommitment(
        bytes32 _comm,
        bytes32 _rollingHash,
        uint256 _height
    )
        external
        onlyCommitteeMembers
        validCommitPreconditions(_height)
        returns (bool)
    {
        //TODO prevent double voting scenario
        require(
            _height > commitments[currentHeight].atHeight &&
                _height >= commitments[candidateHeight].atHeight,
            "votes on the currently ratified or on past commitments are not allowed"
        );

        // if this is a vote for an already proposed candidate but is value conflicts with what is already proposed
        if (_height == candidateHeight && _comm != commitments[candidateHeight].value) {
            flagConflict(_height, _comm);
            return false;
        }

        //TODO: compare that the rolling hash matches expected

        // this committment supercedes the current candidate
        if (_height > candidateHeight) {
            commitments[_height].value = _comm;
            commitments[_height].rollingHash = _rollingHash;
            commitments[_height].atHeight = _height;
            candidateHeight = _height;
            emit CommitmentProposed(_comm, committee.getDLTPublicKeyFor(msg.sender), _height);
        }

        commitments[_height].votes.push(
            Vote({member: msg.sender})
        );

        emit VoteReceived(_height);

        if (commitments[candidateHeight].votes.length >= policy.quorum) {
            if(commitments[currentHeight].atHeight > 0)
             commitments[currentHeight].status = Status.REPLACED;

            commitments[candidateHeight].status = Status.RATIFIED;
            emit CommitmentRatified(
                _comm,
                candidateHeight,
                commitments[candidateHeight].votes.length
            );
            currentHeight = candidateHeight;
        }
        return true;
    }

    /**
	@notice Assign the policy that governs operations of the contract.
	@param quorum the minimum number of nodes that need to vote to ratify a state commitment
	*/
    function setPolicy(uint256 quorum) external onlyAdmin {
        require(quorum > 0, "quorum size cannot be zero");
        policy = Policy({quorum: quorum});
        emit PolicyUpdated(quorum);
    }

    function getPolicy() public view returns (uint256) {
        return policy.quorum;
    }
}
