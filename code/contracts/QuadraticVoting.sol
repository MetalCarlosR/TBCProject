// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;



contract QuadraticVoting {
    struct Proposal {
        string title;
        string description;
        uint256 budget;
        address owner;
        address contrAddr;
        uint votes;
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

    Proposal NULL = Proposal("", "", 0, address(0), address(0), 0, 0);

    uint[] pendingFinantial;
    uint[] pendingSignaling;
    uint[] acceptedFinantial;

    uint256 currentId = 1;

    mapping(uint => mapping(address => uint)) votes;


    constructor(uint256 tPrice, uint256 mTokens) {
        tokenPrice = tPrice;
        maxTokens = mTokens;
        owner = msg.sender;
        open = false;
    }

    modifier onlyOwner() {
        require(
            owner == msg.sender,
            "Only the owner of this contract can access this function"
        );
        _;
    }

    modifier newParticipant() {
        require(
            !participants[msg.sender],
            "Participant already inscribed, pls use the other functions"
        );
        _;
    }

    modifier existingParticipant() {
        require(
            participants[msg.sender],
            "Only participants can access this function"
        );
        _;
    }

    modifier isOpen() {
        require(open, "Voting not open");
        _;
    }


    function openVoting() external payable onlyOwner {
        totalBudget = msg.value;
        open = true;
    }

    function addParticipant() external payable newParticipant {
        if (msg.value < tokenPrice)
            revert("You need to send ether to purchase 1 token");

        uint256 numTokens = msg.value / tokenPrice;
        participants[msg.sender] = true;
        tokens[msg.sender] = numTokens;

        uint256 remainder = msg.value % tokenPrice;
        payable(msg.sender).transfer(remainder);
    }

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
            currentId
        );
        proposals[currentId] = newProposal;
        if (budget > 0) pendingFinantial.push(currentId);
        else pendingSignaling.push(currentId);
        return currentId++;
    }

    function cancelProposal(uint256 id) public isOpen existingParticipant  {

        Proposal storage p = proposals[id];

        if (p.owner == NULL.owner)
            revert("No proposal with that id");
        if (p.owner != msg.sender)
            revert("You can't close a proposal that isn't yours");

        // TODO REMOVE
        if(p.budget > 0){

        }
    }


    function buyTokens() external existingParticipant payable {
        if (msg.value < tokenPrice)
            revert("You need to send ether to purchase 1 token");

        uint256 numTokens = msg.value / tokenPrice;
        tokens[msg.sender] += numTokens;

        uint256 remainder = msg.value % tokenPrice;
        payable(msg.sender).transfer(remainder);
    }


    function sellTokens() public existingParticipant{
        if(tokens[msg.sender] == 0)
            revert("No tokens to sell in your account");

        uint amount = tokens[msg.sender] * tokenPrice;

        tokens[msg.sender] = 0;

        payable(msg.sender).transfer(amount);

    }
}
