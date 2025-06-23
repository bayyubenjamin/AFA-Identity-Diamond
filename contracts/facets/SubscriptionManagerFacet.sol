// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../libraries/DiamondStorage.sol";
import "../interfaces/AggregatorV3Interface.sol"; // Pastikan file ini ada
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract SubscriptionManagerFacet is EIP712 {
    using ECDSA for bytes32;

    AppStorage internal s;
    uint256 private _nextTokenId;

    // --- Events ---
    event IdentityMinted(address indexed user, uint256 indexed tokenId);
    event SubscriptionRenewed(uint256 indexed tokenId, uint256 newExpiration);

    /**
     * @dev Panggil konstruktor EIP712 dengan nama dan versi DApp Anda.
     * Ini penting untuk keamanan tanda tangan (signature).
     */
    constructor() EIP712("AFA-Identity-Diamond", "1") {}

    /**
     * @notice Inisialisasi parameter awal untuk diamond.
     * @dev Hanya bisa dipanggil sekali oleh deployer.
     */
    function initialize(address _verifierAddress, string memory _baseURI) external {
        require(s.contractOwner == address(0), "Already initialized");
        s.contractOwner = msg.sender;
        s.verifierAddress = _verifierAddress;
        s.baseURI = _baseURI;
    }

    // --- Admin Functions ---
    function setPriceInUSD(uint256 _priceInCents) external {
        require(msg.sender == s.contractOwner, "AFA: Must be owner");
        s.priceInUSD = _priceInCents;
    }

    // --- Public Mint & Renew Functions ---
    function mintIdentity(bytes calldata _signature) external payable {
        // 1. Check if user already has an identity
        require(s._addressToTokenId[msg.sender] == 0, "User already has an identity");

        // 2. Verify signature
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(msg.sender)));
        address signer = digest.recover(_signature);
        require(signer == s.verifierAddress, "Invalid signature");
        require(signer != address(0), "Invalid signature: zero address");

        // 3. Process payment (logika placeholder)
        _processPayment();

        // 4. Mint NFT and set attestation
        uint256 tokenId = ++_nextTokenId;
        s._addressToTokenId[msg.sender] = tokenId;
        s._tokenIdToAddress[tokenId] = msg.sender;
        
        // Membuat atestasi premium selama 1 tahun
        s.premiumStatus[tokenId] = Attestation({
            expirationTimestamp: block.timestamp + 365 days,
            issuer: address(this)
        });

        emit IdentityMinted(msg.sender, tokenId);
    }

    // --- Private Helper Functions ---
    function _processPayment() private {
        // Logika untuk memeriksa msg.value terhadap harga dari oracle Chainlink
        // atau menangani pembayaran token ERC20.
        // Implementasi ini sangat bergantung pada kebutuhan spesifik Anda.
        // Contoh:
        // uint256 priceInEth = getPriceFromOracle();
        // require(msg.value >= priceInEth, "Insufficient payment");
    }
}
