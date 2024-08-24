// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./RrpRequesterV0.sol";
import "./FlappyQF.sol";
import "./interfaces/IProxy.sol";

contract FlappyQFFactory is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable usdcToken;
    mapping(uint256 => address) public ethUsdProxies;
    mapping(uint256 => address) public usdcUsdProxies;
    mapping(uint256 => address) public rounds;
    uint256 public roundCount;

    // QRNG variables
    address public airnode;
    bytes32 public endpointIdUint256;
    address public sponsorWallet;
    mapping(bytes32 => address) public requestIdToRound;

    event RoundCreated(
        uint256 indexed roundId,
        address roundAddress,
        uint256 matchingPoolAmount
    );
    event MatchingPoolFunded(uint256 amount);
    event MatchingPoolWithdrawn(uint256 amount);
    event ProxyAddressSet(
        uint256 chainId,
        address ethUsdProxy,
        address usdcUsdProxy
    );
    event RandomNumberRequested(
        bytes32 indexed requestId,
        address roundAddress
    );
    event RandomNumberReceived(bytes32 indexed requestId, uint256 randomNumber);

    error InsufficientMatchingPoolFunds();
    error InvalidEthAmount();
    error InvalidProxyAddress();
    error InvalidPriceData();

    constructor(address _usdcToken) {
        usdcToken = IERC20(_usdcToken);

        // Set proxy addresses for Scroll Testnet (chainId 534351)
        ethUsdProxies[534351] = 0xa47Fd122b11CdD7aad7c3e8B740FB91D83Ce43D1;
        usdcUsdProxies[534351] = 0xa790a882bB695D0286C391C0935a05c347290bdB;

        // Set proxy addresses for Linea Testnet (chainId 59141)
        ethUsdProxies[59141] = 0xa47Fd122b11CdD7aad7c3e8B740FB91D83Ce43D1;
        usdcUsdProxies[59141] = 0xa790a882bB695D0286C391C0935a05c347290bdB;
    }

    function setRequestParameters(
        address _airnode,
        bytes32 _endpointIdUint256,
        address _sponsorWallet
    ) external onlyOwner {
        airnode = _airnode;
        endpointIdUint256 = _endpointIdUint256;
        sponsorWallet = _sponsorWallet;
    }

    function requestRandomNumber(address roundAddress) external {
        require(
            msg.sender == rounds[roundCount - 1],
            "Only current round can request"
        );
        bytes32 requestId = airnodeRrp.makeFullRequest(
            airnode,
            endpointIdUint256,
            address(this),
            sponsorWallet,
            address(this),
            this.fulfillRandomNumber.selector,
            ""
        );
        requestIdToRound[requestId] = roundAddress;
        emit RandomNumberRequested(requestId, roundAddress);
    }

    function fulfillRandomNumber(
        bytes32 requestId,
        bytes calldata data
    ) external onlyAirnodeRrp {
        uint256 randomNumber = abi.decode(data, (uint256));
        address roundAddress = requestIdToRound[requestId];
        FlappyQF(roundAddress).receiveRandomNumber(randomNumber);
        emit RandomNumberReceived(requestId, randomNumber);
    }

    function setProxyAddresses(
        uint256 chainId,
        address ethUsdProxy,
        address usdcUsdProxy
    ) external onlyOwner {
        if (ethUsdProxy == address(0) || usdcUsdProxy == address(0))
            revert InvalidProxyAddress();
        ethUsdProxies[chainId] = ethUsdProxy;
        usdcUsdProxies[chainId] = usdcUsdProxy;
        emit ProxyAddressSet(chainId, ethUsdProxy, usdcUsdProxy);
    }

    function createRound(
        uint256 maxProjects,
        uint256 ethAmount
    ) external onlyOwner returns (address) {
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

        uint256 createdTime = block.timestamp;
        FlappyQF newRound = new FlappyQF(maxProjects, createdTime);
        uint256 roundId = roundCount++;
        rounds[roundId] = address(newRound);

        // Transfer matching pool funds to the new round
        usdcToken.safeTransfer(address(newRound), usdcAmount);

        emit RoundCreated(roundId, address(newRound), usdcAmount);
        return address(newRound);
    }

    function fundMatchingPool(uint256 amount) external onlyOwner {
        usdcToken.safeTransferFrom(msg.sender, address(this), amount);
        emit MatchingPoolFunded(amount);
    }

    function withdrawMatchingPool(uint256 amount) external onlyOwner {
        require(
            usdcToken.balanceOf(address(this)) >= amount,
            "Insufficient funds"
        );
        usdcToken.safeTransfer(msg.sender, amount);
        emit MatchingPoolWithdrawn(amount);
    }
}
