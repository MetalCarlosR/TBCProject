// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;


interface IExecutableProposal{
  function executeProposal(uint proposalId, uint numVotes, uint numTokesn) external payable;
}
