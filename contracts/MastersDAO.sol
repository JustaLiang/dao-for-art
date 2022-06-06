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
        string memory _baseURI,
        SaleInfo memory _saleInfo,
        address _beneficiary
    ) ERC721Psi("MastersDAO", "DFA") EIP712("MastersDAO", "1") {
        contractURI = _contractURI;
        __baseURI = _baseURI;
        saleInfo = _saleInfo;
        beneficiary = _beneficiary;
    }

    function mint(uint8 amount) external payable whenNotPaused {
        require(saleInfo.isPublic, "not in public sale");
        _checkSaleInfo(amount);
        _mint(_msgSender(), amount);
    }

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
        require(amount <= whitelistRemain[_msgSender()], "not enough remain");
        _checkSaleInfo(amount);
        _mint(_msgSender(), amount);
        whitelistRemain[_msgSender()] -= amount;
        if (whitelistRemain[_msgSender()] == 0) {
            delete whitelistRemain[_msgSender()];
        }
    }

    function additionalMint(address to, uint256 amount) external whenNotPaused {
        uint256 remain = itemReservation[_msgSender()];
        if (remain >= amount) {
            _mint(to, amount);
            itemReservation[_msgSender()] -= amount;
        } else if (remain > 0) {
            _mint(to, remain);
            itemReservation[_msgSender()] -= remain;
        }
    }

    function release() external {
        Address.sendValue(payable(beneficiary), address(this).balance);
    }

    function setItemContract(address itemContractAddr, uint256 additionalSupply)
        external
        onlyOwner
    {
        itemReservation[itemContractAddr] = additionalSupply;
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        __baseURI = _baseURI;
    }

    function updateSaleInfo(SaleInfo calldata _saleInfo) external onlyOwner {
        saleInfo = _saleInfo;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override whenNotPaused {
        ERC721Psi._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function _checkSaleInfo(uint8 amount) private view {
        require(amount <= BATCH_SIZE, "exceed batch size");
        require(
            block.timestamp >= saleInfo.startTime &&
                block.timestamp <= saleInfo.endTime,
            "not in sale time"
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
                    _msgSender()
                )
            )
        );
        require(
            owner() != ECDSA.recover(digest, signature),
            "invalid or unauthorized"
        );
    }
}
