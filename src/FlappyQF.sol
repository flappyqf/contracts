// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IFlappyQFFactory {
    function requestRandomNumber(address roundAddress) external;
}

contract FlappyQF is Ownable {
    struct Project {
        string ipfsHash;
        bool accepted;
    }

    uint256 public immutable maxProjects;
    uint256 public immutable roundCreatedTime;
    uint256 public constant ROUND_DURATION = 30 days;

    Project[] public projects;
    mapping(uint256 => mapping(uint256 => bool)) public matchWinners;

    address public immutable factory;
    uint256 public randomNumber;
    bool public randomNumberReceived;

    enum RoundStage {
        Submission,
        Review,
        Matching,
        Voting
    }

    event ProjectSubmitted(uint256 indexed projectId, string ipfsHash);
    event ProjectReviewed(uint256 indexed projectId, bool accepted);
    event MatchingCompleted(uint256[] matchedProjects);
    event RandomNumberReceived(uint256 randomNumber);

    constructor(
        uint256 _maxProjects,
        uint256 _createdTime,
        address _factory
    ) Ownable(msg.sender) {
        maxProjects = _maxProjects;
        roundCreatedTime = _createdTime;
        factory = _factory;
    }

    function submitProject(string memory _ipfsHash) external {
        require(
            block.timestamp < roundCreatedTime + 7 days,
            "Submission period ended"
        );
        require(projects.length < maxProjects, "Max projects reached");
        projects.push(Project(_ipfsHash, false));
        emit ProjectSubmitted(projects.length - 1, _ipfsHash);
    }

    function reviewProject(
        uint256 _projectId,
        bool _accepted
    ) external onlyOwner {
        require(
            block.timestamp >= roundCreatedTime + 7 days &&
                block.timestamp < roundCreatedTime + 14 days,
            "Not in review period"
        );
        require(_projectId < projects.length, "Invalid project ID");
        projects[_projectId].accepted = _accepted;
        emit ProjectReviewed(_projectId, _accepted);
    }

    function initiateMatching() external onlyOwner {
        require(
            block.timestamp >= roundCreatedTime + 14 days &&
                block.timestamp < roundCreatedTime + 21 days,
            "Not in matching period"
        );
        require(!randomNumberReceived, "Random number already received");
        IFlappyQFFactory(factory).requestRandomNumber(address(this));
    }

    function receiveRandomNumber(uint256 _randomNumber) external {
        require(msg.sender == factory, "Only factory can set random number");
        require(!randomNumberReceived, "Random number already received");
        randomNumber = _randomNumber;
        randomNumberReceived = true;
        emit RandomNumberReceived(_randomNumber);
    }

    function completeMatching() external onlyOwner {
        require(
            block.timestamp >= roundCreatedTime + 14 days &&
                block.timestamp < roundCreatedTime + 21 days,
            "Not in matching period"
        );
        require(randomNumberReceived, "Random number not received yet");

        uint256[] memory acceptedProjects = getAcceptedProjects();
        uint256[] memory matchedProjects = new uint256[](
            acceptedProjects.length
        );

        for (uint256 i = 0; i < acceptedProjects.length; i++) {
            uint256 j = i + (randomNumber % (acceptedProjects.length - i));
            matchedProjects[i] = acceptedProjects[j];
            acceptedProjects[j] = acceptedProjects[i];
        }

        emit MatchingCompleted(matchedProjects);
    }

    function setMatchWinner(
        uint256 _round,
        uint256 _match,
        bool _winner
    ) external onlyOwner {
        require(
            block.timestamp >= roundCreatedTime + 21 days &&
                block.timestamp < roundCreatedTime + ROUND_DURATION,
            "Not in voting period"
        );
        matchWinners[_round][_match] = _winner;
    }

    function getAcceptedProjects() internal view returns (uint256[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < projects.length; i++) {
            if (projects[i].accepted) {
                count++;
            }
        }

        uint256[] memory acceptedProjects = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < projects.length; i++) {
            if (projects[i].accepted) {
                acceptedProjects[index] = i;
                index++;
            }
        }

        return acceptedProjects;
    }

    function getCurrentStage() public view returns (RoundStage) {
        uint256 elapsed = block.timestamp - roundCreatedTime;
        if (elapsed < 7 days) return RoundStage.Submission;
        if (elapsed < 14 days) return RoundStage.Review;
        if (elapsed < 21 days) return RoundStage.Matching;
        if (elapsed < ROUND_DURATION) return RoundStage.Voting;
        revert("Round ended");
    }
}
