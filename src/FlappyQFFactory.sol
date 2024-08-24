// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./RrpRequesterV0.sol";
import "./FlappyQF.sol";
import "./interfaces/IProxy.sol";

/// @title FlappyQFFactory - A factory contract for creating and managing FlappyQF instances
/// @author Yudhishthra Sugumaran
/// @notice This contract handles the creation of FlappyQF instances, manages QRNG requests, and handles the matching pool funds
/// @dev Inherits from RrpRequesterV0 for QRNG functionality and Ownable for access control
contract FlappyQFFactory {
    /// @notice The USDC token used for the matching pool
    IERC20 public immutable usdcToken;

    /// @notice The game verifier contract
    address public gameVerifier;

    /// @notice Mapping of chain IDs to ETH/USD price feed proxy addresses
    mapping(uint256 => address) public ethUsdProxies;

    /// @notice Mapping of chain IDs to USDC/USD price feed proxy addresses
    mapping(uint256 => address) public usdcUsdProxies;

    /// @notice Mapping of round IDs to FlappyQF contract addresses
    mapping(uint256 => address) public rounds;

    /// @notice The total number of rounds created
    uint256 public roundCount;

    // QRNG variables
    /// @notice The address of the Airnode for QRNG requests
    address public airnode;

    /// @notice The endpoint ID for uint256 QRNG requests
    bytes32 public endpointIdUint256;

    /// @notice The address of the sponsor wallet for QRNG requests
    address public sponsorWallet;

    /// @notice Mapping of request IDs to round addresses
    mapping(bytes32 => address) public requestIdToRound;

    /// @notice Mapping to track expected QRNG request fulfillments
    mapping(bytes32 => bool) public expectingRequestWithIdToBeFulfilled;

    /// @notice Emitted when a new FlappyQF round is created
    event RoundCreated(
        uint256 indexed roundId,
        address roundAddress,
        uint256 matchingPoolAmount
    );

    /// @notice Emitted when the matching pool is funded
    event MatchingPoolFunded(uint256 amount);

    /// @notice Emitted when funds are withdrawn from the matching pool
    event MatchingPoolWithdrawn(uint256 amount);

    /// @notice Emitted when proxy addresses are set for a chain
    event ProxyAddressSet(
        uint256 chainId,
        address ethUsdProxy,
        address usdcUsdProxy
    );

    /// @notice Emitted when a QRNG request is made
    event RequestedUint256(bytes32 indexed requestId);

    /// @notice Emitted when a QRNG request is fulfilled
    event ReceivedUint256(bytes32 indexed requestId, uint256 response);

    /// @notice Emitted when a withdrawal is requested
    event WithdrawalRequested(
        address indexed airnode,
        address indexed sponsorWallet
    );

    error InsufficientMatchingPoolFunds();
    error InvalidEthAmount();
    error InvalidProxyAddress();
    error InvalidPriceData();
    error RequestIdNotKnown();
    error OnlyRoundContractCanRequest();
    error RoundNotFound();

    /// @notice Modifier to ensure only the FlappyQF round contract can call a function
    /// @param roundId The ID of the round
    modifier onlyRound(uint256 roundId) {
        if (msg.sender != rounds[roundId]) revert OnlyRoundContractCanRequest();
        _;
    }

    /// @notice Constructor to initialize the FlappyQFFactory contract
    /// @param _usdcToken The address of the USDC token contract
    /// @param _airnodeRrp The address of the Airnode RRP contract
    constructor(
        address _usdcToken,
        address _airnodeRrp,
        address _gameVerifier
    ) {
        usdcToken = IERC20(_usdcToken);
        gameVerifier = _gameVerifier;

        // Set proxy addresses for Ethereum Sepolia Testnet (chainId 11155111)
        ethUsdProxies[11155111] = 0x1A4eE81BBbb479f3923f22E315Bc2bD1f6d5d180;
        usdcUsdProxies[11155111] = 0xe8a3E41e620fF07765651a35334c9B6578790ECF;

        // Set proxy addresses for Scroll Testnet (chainId 534351)
        ethUsdProxies[534351] = 0xa47Fd122b11CdD7aad7c3e8B740FB91D83Ce43D1;
        usdcUsdProxies[534351] = 0xa790a882bB695D0286C391C0935a05c347290bdB;

        // Set proxy addresses for Linea Testnet (chainId 59141)
        ethUsdProxies[59141] = 0xa47Fd122b11CdD7aad7c3e8B740FB91D83Ce43D1;
        usdcUsdProxies[59141] = 0xa790a882bB695D0286C391C0935a05c347290bdB;
    }

    /// @notice Sets the parameters for QRNG requests
    /// @param _airnode The address of the Airnode
    /// @param _endpointIdUint256 The endpoint ID for uint256 requests
    /// @param _sponsorWallet The address of the sponsor wallet
    function setRequestParameters(
        address _airnode,
        bytes32 _endpointIdUint256,
        address _sponsorWallet
    ) external {
        airnode = _airnode;
        endpointIdUint256 = _endpointIdUint256;
        sponsorWallet = _sponsorWallet;
    }

    /// @notice Handles incoming ETH transfers
    receive() external payable {
        payable(msg.sender).transfer(msg.value);
        emit WithdrawalRequested(airnode, sponsorWallet);
    }

    /// @notice Makes a QRNG request for a uint256
    /// @param roundId The ID of the round making the request
    // function makeRequestUint256(uint256 roundId) external onlyRound(roundId) {
    //     bytes32 requestId = airnodeRrp.makeFullRequest(
    //         airnode,
    //         endpointIdUint256,
    //         address(this),
    //         sponsorWallet,
    //         address(this),
    //         this.fulfillUint256.selector,
    //         ""
    //     );
    //     expectingRequestWithIdToBeFulfilled[requestId] = true;
    //     requestIdToRound[requestId] = rounds[roundId];
    //     emit RequestedUint256(requestId);
    // }

    /// @notice Fulfills a QRNG request with the received uint256
    /// @param requestId The ID of the request being fulfilled
    /// @param data The received random data
    function fulfillUint256(bytes32 requestId, bytes calldata data) external {
        if (!expectingRequestWithIdToBeFulfilled[requestId])
            revert RequestIdNotKnown();
        expectingRequestWithIdToBeFulfilled[requestId] = false;

        uint256 qrngUint256 = abi.decode(data, (uint256));
        address roundAddress = requestIdToRound[requestId];
        FlappyQF(roundAddress).receiveRandomNumber(qrngUint256);
        emit ReceivedUint256(requestId, qrngUint256);
    }

    /// @notice Sets the proxy addresses for a specific chain
    /// @param chainId The ID of the chain
    /// @param ethUsdProxy The address of the ETH/USD price feed proxy
    /// @param usdcUsdProxy The address of the USDC/USD price feed proxy
    function setProxyAddresses(
        uint256 chainId,
        address ethUsdProxy,
        address usdcUsdProxy
    ) external {
        if (ethUsdProxy == address(0) || usdcUsdProxy == address(0))
            revert InvalidProxyAddress();
        ethUsdProxies[chainId] = ethUsdProxy;
        usdcUsdProxies[chainId] = usdcUsdProxy;
        emit ProxyAddressSet(chainId, ethUsdProxy, usdcUsdProxy);
    }

    /// @notice Creates a new FlappyQF round
    /// @param maxProjects The maximum number of projects allowed in the new FlappyQF instance
    /// @param ethAmount The amount of ETH to convert to USDC for the matching pool
    /// @return address The address of the newly created FlappyQF contract
    function createRound(
        uint256 maxProjects,
        uint256 ethAmount
    ) external returns (address) {
        if (ethAmount == 0) revert InvalidEthAmount();

        address ethUsdProxyAddress = ethUsdProxies[block.chainid];
        address usdcUsdProxyAddress = usdcUsdProxies[block.chainid];
        if (
            ethUsdProxyAddress == address(0) ||
            usdcUsdProxyAddress == address(0)
        ) revert InvalidProxyAddress();

        IProxy ethUsdProxy = IProxy(ethUsdProxyAddress);
        IProxy usdcUsdProxy = IProxy(usdcUsdProxyAddress);

        (int224 ethUsdPrice, ) = ethUsdProxy.read();
        (int224 usdcUsdPrice, ) = usdcUsdProxy.read();

        if (ethUsdPrice <= 0 || usdcUsdPrice <= 0) revert InvalidPriceData();

        uint256 usdAmount = (ethAmount * uint224(ethUsdPrice)) / 1e18;
        uint256 usdcAmount = (usdAmount * 1e6) / uint224(usdcUsdPrice);

        if (usdcToken.balanceOf(address(this)) < usdcAmount) {
            revert InsufficientMatchingPoolFunds();
        }

        FlappyQF newRound = new FlappyQF(
            maxProjects,
            address(this),
            address(usdcToken),
            gameVerifier
        );
        uint256 roundId = roundCount++;
        rounds[roundId] = address(newRound);

        // Transfer matching pool funds to the new project
        usdcToken.transfer(address(newRound), usdcAmount);

        emit RoundCreated(roundId, address(newRound), usdcAmount);
        return address(newRound);
    }

    /// @notice Funds the matching pool with USDC
    /// @param amount The amount of USDC to add to the matching pool
    function fundMatchingPool(uint256 amount) external {
        usdcToken.transferFrom(msg.sender, address(this), amount);

        emit MatchingPoolFunded(amount);
    }

    /// @notice Withdraws USDC from the matching pool
    /// @param amount The amount of USDC to withdraw
    function withdrawMatchingPool(uint256 amount) external {
        require(
            usdcToken.balanceOf(address(this)) >= amount,
            "Insufficient funds"
        );
        usdcToken.transfer(msg.sender, amount);
        emit MatchingPoolWithdrawn(amount);
    }

    /// @notice Gets the round ID for a given round address
    /// @param roundAddress The address of the FlappyQF contract
    /// @return uint256 The ID of the round
    function getRoundId(address roundAddress) external view returns (uint256) {
        for (uint256 i = 0; i < roundCount; i++) {
            if (rounds[i] == roundAddress) {
                return i;
            }
        }
        revert RoundNotFound();
    }

    function setGameVerifier(address _gameVerifier) external {
        gameVerifier = _gameVerifier;
    }
}
