// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IFlappyQFFactory {
    function makeRequestUint256(uint256 projectId) external;
    function getProjectId(
        address projectAddress
    ) external view returns (uint256);
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

    address public immutable factory;
    uint256 public randomNumber;
    bool public randomNumberReceived;

    uint256 public currentRound;
    uint256 public matchesPerRound;
    mapping(uint256 => mapping(uint256 => uint256[2])) public matchParticipants;
    mapping(uint256 => mapping(uint256 => uint256)) public matchWinners;

    enum RoundStage {
        Submission,
        Review,
        Matching,
        Competing
    }

    RoundStage public currentStage;

    event StageAdvanced(RoundStage newStage);

    event ProjectSubmitted(uint256 indexed projectId, string ipfsHash);
    event ProjectAccepted(uint256 indexed projectId);
    event MatchingCompleted(uint256[] matchedProjects);
    event RandomNumberReceived(uint256 randomNumber);
    event MatchCreated(uint256 project1, uint256 project2);
    event MatchWinnerDeclared(
        uint256 round,
        uint256 roundMatch,
        uint256 winner
    );
    event RoundCompleted(uint256 round);
    event TournamentCompleted(uint256 winner);

    error MaxProjectsReached();
    error InvalidProjectId();
    error NotInMatchingPeriod();
    error RandomNumberAlreadyReceived();
    error OnlyFactoryCanSetRandomNumber();
    error RandomNumberNotReceived();
    error CannotAdvancePastVoting();
    error NotInCompetingPeriod();
    error NotInReviewPeriod();
    error NotInSubmissionPeriod();
    error InvalidMatch();
    error InvalidWinner();
    error InvalidMatchNumber();

    modifier onlyFactory() {
        if (msg.sender != factory) revert OnlyFactoryCanSetRandomNumber();
        _;
    }

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
        if (projects.length >= maxProjects) revert MaxProjectsReached();
        if (getCurrentStage() != RoundStage.Submission)
            revert NotInSubmissionPeriod();

        projects.push(Project(_ipfsHash, false));
        emit ProjectSubmitted(projects.length - 1, _ipfsHash);
    }

    function acceptProject(uint256 _projectId) external onlyOwner {
        if (_projectId >= projects.length) revert InvalidProjectId();
        if (getCurrentStage() != RoundStage.Review) revert NotInReviewPeriod();

        projects[_projectId].accepted = true;
        emit ProjectAccepted(_projectId);
    }

    function initiateMatching() external onlyOwner {
        if (getCurrentStage() != RoundStage.Matching)
            revert NotInMatchingPeriod();
        if (randomNumberReceived) revert RandomNumberAlreadyReceived();

        uint256 projectId = IFlappyQFFactory(factory).getProjectId(
            address(this)
        );
        IFlappyQFFactory(factory).makeRequestUint256(projectId);
    }

    function receiveRandomNumber(uint256 _randomNumber) external onlyFactory {
        if (randomNumberReceived) revert RandomNumberAlreadyReceived();
        randomNumber = _randomNumber;
        randomNumberReceived = true;
        emit RandomNumberReceived(_randomNumber);
    }

    function completeMatching() external onlyOwner {
        if (getCurrentStage() != RoundStage.Matching)
            revert NotInMatchingPeriod();
        if (!randomNumberReceived) revert RandomNumberNotReceived();

        uint256[] memory acceptedProjects = getAcceptedProjects();
        uint256 projectCount = acceptedProjects.length;

        // Ensure we have a power of 2 number of projects
        uint256 bracketSize = 1;
        while (bracketSize < projectCount) {
            bracketSize *= 2;
        }

        uint256[] memory bracket = new uint256[](bracketSize);

        // Fill the bracket with accepted projects and byes
        for (uint256 i = 0; i < bracketSize; i++) {
            if (i < projectCount) {
                bracket[i] = acceptedProjects[i];
            } else {
                bracket[i] = type(uint256).max; // Use max uint256 to represent a bye
            }
        }

        // Shuffle the bracket using Fisher-Yates algorithm
        for (uint256 i = bracketSize - 1; i > 0; i--) {
            uint256 j = uint256(keccak256(abi.encodePacked(randomNumber, i))) %
                (i + 1);
            (bracket[i], bracket[j]) = (bracket[j], bracket[i]);
        }

        // Set up initial matches
        currentRound = 1;
        matchesPerRound = bracketSize / 2;
        for (uint256 i = 0; i < bracketSize; i += 2) {
            matchParticipants[currentRound][i / 2] = [
                bracket[i],
                bracket[i + 1]
            ];
            emit MatchCreated(bracket[i], bracket[i + 1]);
        }

        emit MatchingCompleted(bracket);
    }

    //WIP: to be replaced by a MUD framework contract that will handle game logic and pass the winner for the match
    function setMatchWinner(
        uint256 _match,
        uint256 _winner
    ) external onlyOwner {
        if (getCurrentStage() != RoundStage.Competing)
            revert NotInCompetingPeriod();
        if (_match >= matchesPerRound) revert InvalidMatchNumber();

        uint256[2] memory participants = matchParticipants[currentRound][
            _match
        ];
        if (_winner != participants[0] && _winner != participants[1])
            revert InvalidWinner();

        matchWinners[currentRound][_match] = _winner;
        emit MatchWinnerDeclared(currentRound, _match, _winner);

        if (isRoundComplete()) {
            advanceToNextRound();
        }
    }

    function isRoundComplete() internal view returns (bool) {
        for (uint256 i = 0; i < matchesPerRound; i++) {
            if (matchWinners[currentRound][i] == 0) {
                return false;
            }
        }
        return true;
    }

    function advanceToNextRound() internal {
        emit RoundCompleted(currentRound);
        currentRound++;
        matchesPerRound = matchesPerRound / 2;

        if (matchesPerRound == 0) {
            // Tournament is complete
            emit TournamentCompleted(matchWinners[currentRound - 1][0]);
            currentStage = RoundStage.Competing;
        } else {
            // Set up next round matches
            for (uint256 i = 0; i < matchesPerRound; i++) {
                uint256 winner1 = matchWinners[currentRound - 1][i * 2];
                uint256 winner2 = matchWinners[currentRound - 1][i * 2 + 1];
                matchParticipants[currentRound][i] = [winner1, winner2];
                emit MatchCreated(winner1, winner2);
            }
        }
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

    function advanceStage() external onlyOwner {
        if (getCurrentStage() == RoundStage.Competing)
            revert CannotAdvancePastVoting();
        currentStage = RoundStage(uint(currentStage) + 1);

        emit StageAdvanced(currentStage);
    }

    function getCurrentStage() public view returns (RoundStage) {
        return currentStage;
    }
}
