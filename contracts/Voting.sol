// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract Election {
    struct Candidate {
        address addr;
        uint votes;
    }

    struct Voter {
        address addr;
        bool eligible;
        bool voted;
        uint candidateId;

        address[] whitelistedBy;
        uint whitelistCount;
    }

    uint numCandidates = 0;
    uint numVoters = 0;

    mapping(address => uint) candidateId;   // index = Id - 1
    mapping(address => uint) voterId;       // index = Id - 1
    
    uint winnerId;

    bool finished;

    Candidate[] candidates;
    Voter[] voters;

    mapping(address => bool) callEndElection;
    uint endElectionCount = 0;

    constructor(address[] memory _candidates) {
        for(uint i = 0; i < _candidates.length; i ++) {
            candidates.push(Candidate(_candidates[i], 0));
            numCandidates += 1;
            candidateId[_candidates[i]] = numCandidates;
        }
        finished = false;
        winnerId = 0;
    }

    function whitelistVoter(address _voter) external {
        require(!finished, "Election has already finished");
        require(candidateId[msg.sender] > 0, "Only candidate can whitelist the voter");
        if(voterId[_voter] == 0) {
            // add voter into the voters list
            voters.push(Voter(_voter, false, false, 0, new address[](numCandidates), 0));
            numVoters += 1;
            voterId[_voter] = numVoters;
        }
        Voter storage voter = voters[voterId[_voter] - 1];
        require(!voter.eligible, "Voter is already eligible to vote");
        for(uint i = 0; i < voter.whitelistCount; i ++) {
            require(msg.sender != voter.whitelistedBy[i], "Voter has already been whitelisted by you");
        }
        voter.whitelistedBy[voter.whitelistCount] = msg.sender;
        voter.whitelistCount += 1;
        if (voter.whitelistCount == numCandidates) {
            voter.eligible = true;
        }
    }

    function voteCandidate(address _candidate) external {
        require(!finished, "Election has already finished");
        require(candidateId[_candidate] > 0, "Candidate do not exist");
        require(candidateId[msg.sender] == 0, "Only voters can cast vote");
        require(voterId[msg.sender] > 0, "Voter is not added in the election");
        Voter storage voter = voters[voterId[msg.sender] - 1];
        require(voter.eligible, "Voter is not yet eligible to cast vote");
        require(!voter.voted, "Voter has already cast its vote");
        voter.candidateId = candidateId[_candidate];
        voter.voted = true;
        Candidate storage candidate = candidates[candidateId[_candidate] - 1];
        candidate.votes += 1;
    }

    function electionCandidates() public view returns (address[] memory _addresses) {
        _addresses = new address[](candidates.length);
        for(uint i = 0; i < candidates.length; i ++) {
            _addresses[i] = candidates[i].addr;
        }
    }

    function getCandidate(uint _candidateId) public view returns (address) {
        require(_candidateId > 0, "Candidate Id must be > 0");
        require(_candidateId <= candidates.length, "Candidate Id do not exist");
        return candidates[_candidateId - 1].addr;
    }

    function endElection() external {
        // the election will end and the winner will be annouced. Only called when all candiates call this function
        require(!finished, "Election has already finished");
        require(candidateId[msg.sender] > 0, "Only candidate can call this function");
        require(callEndElection[msg.sender] == false, "You have already called this function. Wait for other candidates to call end to election");
        callEndElection[msg.sender] = true;
        endElectionCount += 1;
        if (endElectionCount == numCandidates) {
            // set the winner and mark election as finished
            uint maxVotes = 0;
            for(uint i = 0; i < numCandidates; i ++) {
                if (candidates[i].votes > maxVotes) {
                    maxVotes = candidates[i].votes;
                    winnerId = i + 1;
                }
            }
            finished = true;
        }

    }

    function getWinningCandidate() public view returns (address) {
        require(finished, "The election is still running");
        return candidates[winnerId - 1].addr;
    }

}

