// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import "./VotingTokensERC20.sol";
import "../interfaces/IExecutableProposal.sol";

contract QuadraticVoting {
    // Proposal structure
    struct Proposal {
        string title;
        string description;
        // Budget in tokens
        uint256 budget;
        address owner;
        address contrAddr;
        // Tokens recieved from votes
        uint256 tokens;
        uint256 votes;
        uint256 id;
        bool approved;
    }

    uint256 tokenPrice;
    uint256 maxTokens;
    uint256 totalBudget;
    address owner;
    bool open;
    VotingTokensERC20 erc20;

    mapping(address => bool) participants;
    address[] participantsArray;

    mapping(uint256 => Proposal) proposals;

    // "NULL" Proposal for visual checking (not necessary but checking with "NULL" is easier)
    Proposal NULL = Proposal("", "", 0, address(0), address(0), 0, 0, 0, false);

    uint256[] pendingFinantial;
    uint256[] pendingSignaling;
    uint256[] approvedFinantial;

    uint256 currentId = 1;

    // Mapping from Proposal id to votes (formated from tokens to facilitate quadratic formula) from participant address
    mapping(uint256 => mapping(address => uint256)) votes;

    // Just initialize simple parameters
    constructor(uint256 tPrice, uint256 mTokens) {
        tokenPrice = tPrice;
        maxTokens = mTokens;
        owner = msg.sender;
        open = false;
        erc20 = new VotingTokensERC20(owner);
    }

    // Modifier to check for owner
    modifier onlyOwner() {
        require(
            owner == msg.sender,
            "Only the owner of this contract can access this function"
        );
        _;
    }

    // Modifier to check if sender is not a participant
    modifier newParticipant() {
        require(
            !participants[msg.sender],
            "Participant already inscribed, pls use the other functions"
        );
        _;
    }

    // Modifier to check if sender is a participant
    modifier existingParticipant() {
        require(
            participants[msg.sender],
            "Only participants can access this function"
        );
        _;
    }

    // Modifier to check if proposal exist
    modifier existingProposal(uint256 id) {
        require(
            proposals[id].contrAddr != NULL.contrAddr,
            "Non existing proposal"
        );
        _;
    }

    // Modifier to check if proposal is not approved yet
    modifier notApproved(uint256 id) {
        require(
            proposals[id].approved == false,
            "Only participants can access this function"
        );
        _;
    }

    // Modifier to check if poll is open
    modifier isOpen() {
        require(open, "Voting not open");
        _;
    }

    // Open the voting and assing an inital budget
    function openVoting() external payable onlyOwner {
        totalBudget = msg.value;
        open = true;
    }

    // Function that an external address can call to be added
    // as a participant. Checks if it is already and reverts
    // if needed. Also adds tokens for the value of message
    // The call value must cover for at least 1 token
    function addParticipant() external payable newParticipant {
        if (msg.value < tokenPrice)
            revert("You need to send ether to purchase 1 token");

        uint256 numTokens = msg.value / tokenPrice;
        participants[msg.sender] = true;
        erc20.addTokens(msg.sender, numTokens);

        uint256 remainder = msg.value % tokenPrice;
        payable(msg.sender).transfer(remainder);
    }

    // Function to create a new proposal for the current voting
    // Creates the proposals and stores it on the mapping with a new id
    // It also checks if it's a signaling or not so it can be added to
    // the correct list.
    function addProposal(
        string memory title,
        string memory description,
        uint256 budget,
        address contrAddr
    ) public existingParticipant isOpen returns (uint256) {
        Proposal memory newProposal = Proposal(
            title,
            description,
            budget,
            msg.sender,
            contrAddr,
            0,
            0,
            currentId,
            false
        );
        proposals[currentId] = newProposal;
        if (budget > 0) {
            pendingFinantial.push(currentId);
        } else pendingSignaling.push(currentId);
        return currentId++;
    }

    // TODO TODO TODO TODO TODO TODO TODO TODO TODO
    // TODO TODO TODO TODO TODO TODO TODO TODO TODO
    // TODO TODO TODO TODO TODO TODO TODO TODO TODO
    // TODO TODO TODO TODO TODO TODO TODO TODO TODO
    // TODO TODO TODO TODO TODO TODO TODO TODO TODO
    function cancelProposal(uint256 id)
        public
        isOpen
        existingParticipant
        existingProposal(id)
        notApproved(id)
    {
        Proposal storage p = proposals[id];

        if (p.owner != msg.sender)
            revert("You can't close a proposal that isn't yours");

        // TODO REMOVE
        if (p.budget > 0) {}
    }

    function buyTokens() external payable existingParticipant {
        if (msg.value < tokenPrice)
            revert("You need to send ether to purchase 1 token");

        uint256 numTokens = msg.value / tokenPrice;
        erc20.addTokens(msg.sender, numTokens);

        uint256 remainder = msg.value % tokenPrice;
        payable(msg.sender).transfer(remainder);
    }

    function sellTokens() public existingParticipant {
        uint256 numTokens = erc20.balanceOf(msg.sender);

        if (numTokens == 0) revert("No tokens to sell in your account");

        uint256 amount = numTokens * tokenPrice;

        erc20.eraseBalance(msg.sender);

        payable(msg.sender).transfer(amount);
    }

    // TODO TODO TODO TODO TODO TODO TODO TODO TODO
    // TODO TODO TODO TODO TODO TODO TODO TODO TODO
    // TODO TODO TODO TODO TODO TODO TODO TODO TODO
    // TODO TODO TODO TODO TODO TODO TODO TODO TODO
    // TODO TODO TODO TODO TODO TODO TODO TODO TODO
    function stake(uint256 id, uint256 votesN)
        external
        isOpen
        existingParticipant
        existingProposal(id)
        notApproved(id)
    {
        uint256 v = votes[id][msg.sender];
        uint256 tokens = tokenQuadratic(v + 1, v + votesN);
        require(
            tokens <= erc20.balanceOf(msg.sender),
            "Not enough tokens to make that vote"
        );

        erc20.adminTrasnfer(msg.sender, tokens);

        votes[id][msg.sender] += votesN;
        proposals[id].tokens += tokens;
        proposals[id].votes += votesN;

        _checkAndExecuteProposal(id);

        // TODO CHECK IF ITS APPROVED
    }

    function withdrawFromProposal(uint256 id, uint256 votesN)
        external
        isOpen
        existingParticipant
        existingProposal(id)
        notApproved(id)
    {
        uint256 v = votes[id][msg.sender];

        require(
            v >= votesN,
            "You can't withdraw more votes than you have deposit"
        );

        uint256 tokens = tokenQuadratic(v - votesN + 1, v);

        votes[id][msg.sender] -= votesN;
        erc20.transfer(msg.sender, tokens);

        proposals[id].tokens -= tokens;
        proposals[id].votes -= votesN;
    }

    function _checkAndExecuteProposal(uint256 id)
        internal
        isOpen
        existingParticipant
        existingProposal(id)
        notApproved(id)
    {
        Proposal storage p = proposals[id];

        uint threshold = (2 + (p.budget*10)/(totalBudget*10)) * participantsArray.length*10 + (pendingFinantial.length*10 + pendingSignaling.length*10);


        uint tokensBudget = tokensToEther(p.tokens);
        if (p.budget == 0 || p.budget > (tokensBudget + totalBudget) || threshold > p.votes*10) return;

        p.approved = true;
        erc20.removeTokens(owner, p.tokens);

        removeFromArray(id, pendingFinantial);
        approvedFinantial.push(id);

        bytes memory data = abi.encodeWithSignature(
            "executeProposal(uint,uint,uint)",
            p.id,
            p.votes,
            p.tokens
        );
        (bool success, ) = p.contrAddr.call{value: p.budget, gas: 1000000}(
            data
        );

        require(success, "Error calling proposal contract");
    }

    function closeVoting() external onlyOwner isOpen {
        // Finantial proposals
        open = false;

        while (pendingFinantial.length > 0) {
            uint256 id = pendingFinantial[pendingFinantial.length - 1];

            for (uint256 j = 0; j < participantsArray.length; j++) {
                address p = participantsArray[j];

                uint256 v = votes[id][p];

                if (v > 0) {
                    uint256 tokens = tokenQuadratic(1, v);
                    erc20.transfer(p, tokens);
                }
            }
            pendingFinantial.pop();
        }

        // Signaling proposals
        while (pendingSignaling.length > 0) {
            uint256 id = pendingSignaling[pendingFinantial.length - 1];

            for (uint256 j = 0; j < participantsArray.length; j++) {
                address p = participantsArray[j];

                uint256 v = votes[id][p];

                if (v > 0) {
                    uint256 tokens = tokenQuadratic(1, v);
                    erc20.transfer(p, tokens);
                }
            }

            Proposal storage p = proposals[id];

            bytes memory data = abi.encodeWithSignature(
                "executeProposal(uint,uint,uint)",
                p.id,
                p.votes,
                0
            );
            (bool success, ) = p.contrAddr.call{value: 0, gas: 1000000}(data);

            require(success, "Error calling proposal contract");

            pendingFinantial.pop();
        }



    }

    // Returns erc20 contract address
    function getERC20() public view returns (address) {
        return address(erc20);
    }

    // Returns pending finantial proposals
    function getPendingProposals()
        public
        view
        isOpen
        returns (uint256[] memory)
    {
        return pendingFinantial;
    }

    // Returns approved finantial proposals
    function getApprovedProposals()
        public
        view
        isOpen
        returns (uint256[] memory)
    {
        return approvedFinantial;
    }

    // Returns pending signaling proposals
    function getSignalingProposals()
        public
        view
        isOpen
        returns (uint256[] memory)
    {
        return pendingSignaling;
    }

    // Returns Proposal struct info from a current
    // proposal. Reverts if it doesn't exist.

    function getProposalInfo(uint256 id)
        public
        view
        isOpen
        existingProposal(id)
        returns (Proposal memory)
    {
        return proposals[id];
    }

    // TODO TODO TODO TODO TODO TODO TODO TODO TODO
    // TODO TODO TODO TODO TODO TODO TODO TODO TODO
    // TODO TODO TODO TODO TODO TODO TODO TODO TODO
    // TODO TODO TODO TODO TODO TODO TODO TODO TODO
    // TODO TODO TODO TODO TODO TODO TODO TODO TODO
    function tokenQuadratic(uint256 firstVote, uint256 lastVote)
        private
        view
        returns (uint256)
    {
        return firstVote * lastVote;
    }

    function tokensToEther(uint256 n) private view returns (uint256) {
        return n * tokenPrice;
    }

    function etherToTokens(uint256 n) private view returns (uint256) {
        return n / tokenPrice;
    }

    function removeFromArray(uint256 remove, uint256[] storage array) private {
        uint256 i;
        for (i = 0; i < array.length; i++) {
            if (array[i] == remove) {
                array[i] = array[array.length - 1];
                array.pop();
                return;
            }
        }
    }
}
