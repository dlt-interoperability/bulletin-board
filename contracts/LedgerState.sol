// SPDX-License-Identifier: MIT
pragma solidity >0.7.0;
pragma experimental ABIEncoderV2;
import "./StringUtils.sol";

contract LedgerStateContract {
    struct StateAccumulator {
        bytes32 value;
        uint height;
        bool ratified;
        uint votesTally;
    }

    struct Policy {
        uint quorum;
    }

    event AccumulatorProposed(
        bytes32 indexed accumulator,
        string member,
        bytes32 signature,
        uint indexed height
    );

    event VoteReceived(
        bytes32 indexed accumulator,
        string member,
        bytes32 signature,
        uint indexed heightt
    );

    event AccumulatorRatified(
        bytes32 indexed accumulator,
        uint indexed height
    );

    event AccumulatorConflictDetected(
        uint indexed height,
        bytes32 assumedAcc,
        bytes32 conflictingAcc,
        bytes32 signature,
        string member
    );

    mapping(address => string) committee;
    mapping(uint => StateAccumulator) accumulators;
    uint currAcc;
    uint candAcc;
    address admin;
    Policy policy;

    constructor() {
        admin = msg.sender;
    }

    function setCommittee(
        address[] calldata memEthAdds,
        string[] calldata memDLTAdds
    ) external returns (bool) {
        require(
            memEthAdds.length == memDLTAdds.length,
            "For each member in the committe there should be an Ethereum address and a corresponding public key in the permissioned DLT"
        );
        for (uint i = 0; i < memEthAdds.length; i++) {
            committee[memEthAdds[i]] = memDLTAdds[i];
        }
    }

    /**
	@notice Get the latest ratified accumulator
	@return the latest accumulator and the ledger height for which it was computed
	*/
    function getAccumulator() external view returns (bytes32, uint) {
        return (accumulators[currAcc].value, accumulators[currAcc].height);
    }

    function addAccumulator(
        bytes32 _acc,
        bytes32 _signature,
        uint _height
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
            accumulators[candAcc].votesTally +=1;
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
    function setPolicy(uint quorum) external {
        require(msg.sender == admin, "only the admin can update policy");
        policy = Policy({quorum: quorum});
    }

    function getAdmin() public view returns (address) {
        return admin;
    }

    function isEmpty(string memory str) private pure returns (bool) {
        return StringUtils.equal(str, "");
    }
}
