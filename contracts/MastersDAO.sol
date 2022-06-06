//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721psi/contracts/ERC721Psi.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract MastersDAO is ERC721Psi, Ownable, Pausable, EIP712 {
    using BitMaps for BitMaps.BitMap;

    uint16 public constant ORIGINAL_SUPPLY = 10000;

    uint8 private constant BATCH_SIZE = 5;

    string public contractURI;

    string private __baseURI;

    BitMaps.BitMap private _voucherRedeemed;

    mapping(address => uint256) public itemReservation;

    mapping(address => uint256) public whitelistRemain;

    address public immutable beneficiary;

    uint256 public claimDeadline;

    struct SaleInfo {
        bool isPublic;
        uint32 startTime;
        uint32 endTime;
        uint160 price;
    }
    SaleInfo public saleInfo;

    struct NFTVoucher {
        uint256 index;
        uint256 amount;
        address redeemer;
    }

    constructor(
        string memory _contractURI,
        string memory _initBaseURI,
        SaleInfo memory _saleInfo,
        address _beneficiary
    ) ERC721Psi("MastersDAO", "M-DAO") EIP712("MastersDAO", "1") {
        contractURI = _contractURI;
        __baseURI = _initBaseURI;
        saleInfo = _saleInfo;
        beneficiary = _beneficiary;
    }

    /// @dev Mint (for everyone)
    function mint(uint8 amount) external payable whenNotPaused {
        require(saleInfo.isPublic, "not in public sale");
        _checkSaleInfo(amount);
        _mint(msg.sender, amount);
        Address.sendValue(payable(beneficiary), msg.value);
    }

    /// @dev Mint (for whitelist members)
    function whitelistMint(
        NFTVoucher calldata voucher,
        bytes calldata signature,
        uint8 amount
    ) external payable whenNotPaused {
        require(!saleInfo.isPublic, "not in whitelist sale");
        if (!_voucherRedeemed.get(voucher.index)) {
            _verify(voucher, signature);
            whitelistRemain[voucher.redeemer] += voucher.amount;
            _voucherRedeemed.set(voucher.index);
        }
        require(amount <= whitelistRemain[msg.sender], "not enough remain");
        _checkSaleInfo(amount);
        _mint(msg.sender, amount);
        whitelistRemain[msg.sender] -= amount;
        if (whitelistRemain[msg.sender] == 0) {
            delete whitelistRemain[msg.sender];
        }
        Address.sendValue(payable(beneficiary), msg.value);
    }

    /// @dev Called by item contracts
    function additionalMint(address to, uint256 amount) external whenNotPaused {
        uint256 remain = itemReservation[msg.sender];
        if (remain >= amount) {
            _mint(to, amount);
            itemReservation[msg.sender] -= amount;
        } else if (remain > 0) {
            _mint(to, remain);
            itemReservation[msg.sender] -= remain;
        }
    }

    /// @dev Owner can take snapshot to allow holders to claim
    function takeSnapShot() external onlyOwner {
        _pause();
        claimDeadline = block.timestamp + 7 days;
    }

    /// @dev Token holders can claim rewards
    function claim() external whenPaused {
        require(block.timestamp <= claimDeadline, "claim due");
        Address.sendValue(
            payable(msg.sender),
            (address(this).balance * balanceOf(msg.sender)) / totalSupply()
        );
    }

    /// @dev Additional issuance when new items created
    function setItemContract(address itemContractAddr, uint256 additionalSupply)
        external
        onlyOwner
    {
        itemReservation[itemContractAddr] = additionalSupply;
    }

    /// @dev Set __baseURI to reveal blindbox
    function setBaseURI(string calldata baseURI) external onlyOwner {
        __baseURI = baseURI;
    }

    /// @dev Owner can update sale info
    function updateSaleInfo(SaleInfo calldata _saleInfo) external onlyOwner {
        saleInfo = _saleInfo;
    }

    /// @dev Owner can pause
    function pause() external onlyOwner {
        _pause();
    }

    /// @dev Owner can unpause
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @dev Override _baseURI()
    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }

    /// @dev Integrate Pausable
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override whenNotPaused {
        ERC721Psi._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    /// @dev Check sale condition
    function _checkSaleInfo(uint8 amount) private view {
        require(amount <= BATCH_SIZE, "exceed batch size");
        require(
            block.timestamp >= saleInfo.startTime &&
                block.timestamp <= saleInfo.endTime,
            "not in saling time"
        );
        require(totalSupply() + amount <= ORIGINAL_SUPPLY, "exceed supply");
        require(saleInfo.price * amount >= msg.value, "not enough fund");
    }

    /// @dev Verify voucher
    function _verify(NFTVoucher calldata voucher, bytes calldata signature)
        private
        view
    {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "NFTVoucher(uint256 index,uint256 amount,address redeemer)"
                    ),
                    voucher.index,
                    voucher.amount,
                    msg.sender
                )
            )
        );
        require(
            owner() == ECDSA.recover(digest, signature),
            "invalid or unauthorized"
        );
    }
}
