// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

contract QuadraticVoting {

    // Proposal structure
    struct Proposal {
        string title;
        string description;
        uint256 budget;
        address owner;
        address contrAddr;
        uint256 votes;
        uint256 id;
    }

    uint256 tokenPrice;
    uint256 maxTokens;
    uint256 totalBudget;
    address owner;
    bool open;

    mapping(address => bool) participants;
    mapping(address => uint256) tokens;
    mapping(uint256 => Proposal) proposals;


    // "NULL" Proposal for visual checking (not necessary but checking with "NULL" is easier)
    Proposal NULL = Proposal("", "", 0, address(0), address(0), 0, 0);

    uint256[] pendingFinantial;
    uint256[] pendingSignaling;
    uint256[] approvedFinantial;

    uint256 currentId = 1;

    // Mapping from Proposal id to votes from participant address
    mapping(uint256 => mapping(address => uint256)) votes;


    // Just initialize simple parameters
    constructor(uint256 tPrice, uint256 mTokens) {
        tokenPrice = tPrice;
        maxTokens = mTokens;
        owner = msg.sender;
        open = false;
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
        tokens[msg.sender] = numTokens;

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
            currentId
        );
        proposals[currentId] = newProposal;
        if (budget > 0) pendingFinantial.push(currentId);
        else pendingSignaling.push(currentId);
        return currentId++;
    }

    // TODO TODO TODO TODO TODO TODO TODO TODO TODO
    // TODO TODO TODO TODO TODO TODO TODO TODO TODO
    // TODO TODO TODO TODO TODO TODO TODO TODO TODO
    // TODO TODO TODO TODO TODO TODO TODO TODO TODO
    // TODO TODO TODO TODO TODO TODO TODO TODO TODO
    function cancelProposal(uint256 id) public isOpen existingParticipant {
        Proposal storage p = proposals[id];

        if (p.owner == NULL.owner) revert("No proposal with that id");
        if (p.owner != msg.sender)
            revert("You can't close a proposal that isn't yours");

        // TODO REMOVE
        if (p.budget > 0) {}
    }

    function buyTokens() external payable existingParticipant {
        if (msg.value < tokenPrice)
            revert("You need to send ether to purchase 1 token");

        uint256 numTokens = msg.value / tokenPrice;
        tokens[msg.sender] += numTokens;

        uint256 remainder = msg.value % tokenPrice;
        payable(msg.sender).transfer(remainder);
    }

    function sellTokens() public existingParticipant {
        if (tokens[msg.sender] == 0)
            revert("No tokens to sell in your account");

        uint256 amount = tokens[msg.sender] * tokenPrice;

        tokens[msg.sender] = 0;

        payable(msg.sender).transfer(amount);
    }


    // TODO TODO TODO TODO TODO TODO TODO TODO TODO
    // TODO TODO TODO TODO TODO TODO TODO TODO TODO
    // TODO TODO TODO TODO TODO TODO TODO TODO TODO
    // TODO TODO TODO TODO TODO TODO TODO TODO TODO
    // TODO TODO TODO TODO TODO TODO TODO TODO TODO
    function getERC20() public view returns (address) {
        // TODO
        return owner;
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
        returns (Proposal memory)
    {
        Proposal storage p = proposals[id];
        if (p.owner == NULL.owner) revert("No proposal with that id");
        return p;
    }

    


}
