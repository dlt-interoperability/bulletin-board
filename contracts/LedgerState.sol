// SPDX-License-Identifier: MIT
pragma solidity >0.4;
pragma experimental ABIEncoderV2;
import "./StringUtils.sol";

contract LedgerState {
    struct StateAccumulator {
        bytes32 value;
        uint256 height;
        bool ratified;
        uint256 votesTally;
    }

    struct Policy {
        uint256 quorum;
    }

    event AccumulatorProposed(
        bytes32 indexed accumulator,
        string member,
        bytes32 signature,
        uint256 indexed height
    );

    event VoteReceived(
        bytes32 indexed accumulator,
        string member,
        bytes32 signature,
        uint256 indexed heightt
    );

    event AccumulatorRatified(
        bytes32 indexed accumulator,
        uint256 indexed height
    );

    event AccumulatorConflictDetected(
        uint256 indexed height,
        bytes32 assumedAcc,
        bytes32 conflictingAcc,
        bytes32 signature,
        string member
    );

    mapping(address => string) committee;
    mapping(uint256 => StateAccumulator) accumulators;
    mapping(uint256 => address) committeeIndex;
    uint256 committeeSize;

    Policy policy;
    uint256 currAcc;
    uint256 candAcc;
    address admin;

    constructor() public {
        admin = msg.sender;
    }

    function setManagementCommittee(
        address[] calldata memEthAdds,
        string[] calldata memDLTPubKeys
    ) external returns (bool) {
        require(
            memEthAdds.length == memDLTPubKeys.length,
            "For each member in the committe there should be an Ethereum address and a corresponding public key in the permissioned DLT"
        );
        committeeSize = memEthAdds.length;
        for (uint256 i = 0; i < memEthAdds.length; i++) {
            committee[memEthAdds[i]] = memDLTPubKeys[i];
            committeeIndex[i] = memEthAdds[i];
        }
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
	@notice Get the latest ratified accumulator
	@return the latest accumulator and the ledger height for which it was computed
	*/
    function getAccumulator() external view returns (bytes32, uint256) {
        return (accumulators[currAcc].value, accumulators[currAcc].height);
    }

    function addAccumulator(
        bytes32 _acc,
        bytes32 _signature,
        uint256 _height
    ) external returns (bool) {
        require(
            _height > accumulators[currAcc].height &&
                _height > accumulators[candAcc].height,
            "votes on already ratified accumulators are not allowed"
        );

        require(
            !isEmpty(committee[msg.sender]),
            "voter is not a known committee member"
        );

        require(
            policy.quorum != 0,
            "a policy for quorum size has not been configured yet"
        );

        if (_height == candAcc) {
            if (_acc == accumulators[candAcc].value) {
                emit AccumulatorConflictDetected(
                    _height,
                    accumulators[candAcc].value,
                    _acc,
                    _signature,
                    committee[msg.sender]
                );
                return false;
            }
            accumulators[candAcc].votesTally += 1;
            if (accumulators[candAcc].votesTally >= policy.quorum) {
                accumulators[candAcc].ratified = true;
                emit AccumulatorRatified(_acc, _height);
            }
        } else {
            accumulators[_height] = StateAccumulator({
                value: _acc,
                height: _height,
                votesTally: 1,
                ratified: false
            });
            candAcc = _height;
            return true;
        }
    }

    /**
	@notice Assign the policy that governs operations of the contract.
	@param quorum the minimum number of nodes that need to vote to ratify a state committment
	*/
    function setPolicy(uint256 quorum) external {
        require(msg.sender == admin, "only the admin can update policy");
        policy = Policy({quorum: quorum});
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
