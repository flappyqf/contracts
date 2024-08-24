// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IFlappyQFFactory {
    function makeRequestUint256(uint256 projectId) external;
    function getRoundId(address roundAddress) external view returns (uint256);
}

/// @title FlappyQF - A contract for managing a quadratic funding round with a tournament-style voting system
/// @author Yudhishthra Sugumaran
/// @notice This contract handles project submissions, reviews, matching, and a tournament-style voting process
/// @dev Inherits from OpenZeppelin's Ownable contract for access control
contract FlappyQF is Ownable {
    /// @notice Struct to represent a project in the funding round
    /// @param ipfsHash IPFS hash containing project details
    /// @param accepted Boolean indicating if the project has been accepted for the round
    struct Project {
        string ipfsHash;
        bool accepted;
    }

    /// @notice Maximum number of projects allowed in this round
    uint256 public immutable maxProjects;

    /// @notice Duration of the round (30 days)
    uint256 public constant ROUND_DURATION = 30 days;

    /// @notice Array of all submitted projects
    Project[] public projects;

    /// @notice Address of the factory contract that created this FlappyQF instance
    address public immutable factory;

    /// @notice Random number received from the factory for matching
    uint256 public randomNumber;

    /// @notice Current round number in the tournament
    uint256 public currentRound;

    /// @notice Number of matches in the current round
    uint256 public matchesPerRound;

    /// @notice Mapping to store match participants for each round
    mapping(uint256 => mapping(uint256 => uint256[2])) public matchParticipants;

    /// @notice Mapping to store match winners for each round
    mapping(uint256 => mapping(uint256 => uint256)) public matchWinners;

    /// @notice Enum to represent the different stages of the round
    enum RoundStage {
        QuarterFinals,
        SemiFinals,
        Finals,
        Completed
    }

    /// @notice Current stage of the round
    RoundStage public currentStage;

    /// @notice Emitted when the round stage is advanced
    event StageAdvanced(RoundStage newStage);

    /// @notice Emitted when a new project is submitted
    event ProjectSubmitted(uint256 indexed projectId, string ipfsHash);

    /// @notice Emitted when a project is accepted
    event ProjectAccepted(uint256 indexed projectId);

    /// @notice Error emitted when trying to advance past the completed stage
    error CannotAdvancePastCompleted();

    /// @notice Emitted when a random number is received from the factory
    event RandomNumberReceived(uint256 randomNumber);

    /// @notice Emitted when a new match is created
    event MatchCreated(uint256 project1, uint256 project2);

    /// @notice Emitted when a match winner is declared
    event MatchWinnerDeclared(
        uint256 round,
        uint256 roundMatch,
        uint256 winner
    );

    /// @notice Emitted when a round is completed
    event RoundCompleted(uint256 round);

    /// @notice Emitted when the tournament is completed
    event TournamentCompleted(uint256 winner);

    /// @notice Error emitted when the maximum number of projects is reached
    event MatchingCompleted(uint256[] bracket);

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

    /// @notice Modifier to ensure only the factory contract can call a function
    modifier onlyFactory() {
        if (msg.sender != factory) revert OnlyFactoryCanSetRandomNumber();
        _;
    }

    /// @notice Constructor to initialize the FlappyQF contract
    /// @param _maxProjects Maximum number of projects allowed
    /// @param _factory Address of the factory contract
    constructor(uint256 _maxProjects, address _factory) Ownable(msg.sender) {
        maxProjects = _maxProjects;
        factory = _factory;
        currentStage = RoundStage.QuarterFinals;
    }

    /// @notice Allows users to submit a project to the funding round
    /// @param _ipfsHash IPFS hash containing project details
    function submitProject(string memory _ipfsHash) external {
        if (projects.length >= maxProjects) revert MaxProjectsReached();

        projects.push(Project(_ipfsHash, false));
        emit ProjectSubmitted(projects.length - 1, _ipfsHash);
    }

    /// @notice Allows the owner to accept a submitted project
    /// @param _projectId ID of the project to accept
    function acceptProject(uint256 _projectId) external {
        if (_projectId >= projects.length) revert InvalidProjectId();

        projects[_projectId].accepted = true;
        emit ProjectAccepted(_projectId);
    }

    /// @notice Initiates the matching process by requesting a random number from the factory
    function initiateMatching() external {
        uint256 projectId = IFlappyQFFactory(factory).getRoundId(address(this));

        //if not on chainid 11155111, use a different way
        if (block.chainid == 11155111) {
            IFlappyQFFactory(factory).makeRequestUint256(projectId);
        } else {
            randomNumber = uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.prevrandao,
                        projectId
                    )
                )
            );
        }
    }

    /// @notice Receives the random number from the factory
    /// @param _randomNumber The random number received
    function receiveRandomNumber(uint256 _randomNumber) external onlyFactory {
        randomNumber = _randomNumber;
        emit RandomNumberReceived(_randomNumber);
    }

    /// @notice Completes the matching process by creating the tournament bracket
    function completeMatching() external {
        if (randomNumber == 0) revert RandomNumberNotReceived();

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

        // Set the current stage to QuarterFinals if not already set
        currentStage = RoundStage.QuarterFinals;

        emit MatchingCompleted(bracket);
    }

    /// @notice Sets the winner for a specific match
    /// @dev To be replaced by a MUD framework contract that will handle game logic
    /// @param _match The match number
    /// @param _winner The ID of the winning project
    function setMatchWinner(
        uint256 _match,
        uint256 _winner
    ) external onlyOwner {
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

    /// @notice Checks if the current round is complete
    /// @return bool True if all matches in the current round have winners
    function isRoundComplete() internal view returns (bool) {
        for (uint256 i = 0; i < matchesPerRound; i++) {
            if (matchWinners[currentRound][i] == 0) {
                return false;
            }
        }
        return true;
    }

    /// @notice Advances the tournament to the next round
    function advanceToNextRound() internal {
        emit RoundCompleted(currentRound);
        currentRound++;
        matchesPerRound = matchesPerRound / 2;

        if (matchesPerRound == 0) {
            // Tournament is complete
            emit TournamentCompleted(matchWinners[currentRound - 1][0]);
            currentStage = RoundStage.Completed;
        } else {
            // Set up next round matches
            for (uint256 i = 0; i < matchesPerRound; i++) {
                uint256 winner1 = matchWinners[currentRound - 1][i * 2];
                uint256 winner2 = matchWinners[currentRound - 1][i * 2 + 1];
                matchParticipants[currentRound][i] = [winner1, winner2];
                emit MatchCreated(winner1, winner2);
            }
            // Advance to the next stage
            currentStage = RoundStage(uint(currentStage) + 1);
        }
    }

    /// @notice Gets an array of accepted project IDs
    /// @return uint256[] An array of accepted project IDs
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

    /// @notice Gets the current stage of the round
    /// @return RoundStage The current stage of the round
    function getCurrentStage() public view returns (RoundStage) {
        return currentStage;
    }

    function getBracketByRound(
        uint256 _round
    ) public view returns (uint256[] memory) {
        uint256[] memory bracket = new uint256[](matchesPerRound * 2);
        for (uint256 i = 0; i < matchesPerRound; i++) {
            bracket[i * 2] = matchParticipants[_round][i][0];
            bracket[i * 2 + 1] = matchParticipants[_round][i][1];
        }
        return bracket;
    }
}
