// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract ReverseDutchAuctionSwap is Ownable {
    struct Auction {
        address seller;
        address tokenAddress;
        uint256 tokenAmount;
        uint256 initialPrice;
        uint256 priceDecreaseRate;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        bool isSold;
    }

    mapping(uint256 => Auction) public auctions;
    uint256 public nextAuctionId;

    event AuctionCreated(
        uint256 indexed auctionId,
        address indexed seller,
        address tokenAddress,
        uint256 tokenAmount,
        uint256 initialPrice,
        uint256 startTime,
        uint256 endTime
    );

    event AuctionExecuted(
        uint256 indexed auctionId,
        address indexed buyer,
        uint256 finalPrice
    );

    event AuctionCancelled(uint256 indexed auctionId);

    error Unauthorized();
    error InvalidAmount();
    error InvalidPrice();
    error InvalidDuration();
    error InvalidRate();
    error InActiveAuction();
    error AlreadySold();
    error AuctionEnded();

    constructor() Ownable(msg.sender) {
        nextAuctionId = 1;
    }

    function createAuction(
        address _tokenAddress,
        uint256 _tokenAmount,
        uint256 _initialPrice,
        uint256 _durationInSeconds,
        uint256 _priceDecreaseRate
    ) external returns (uint256) {
        if (_tokenAddress == address(0)) revert Unauthorized();
        if (_tokenAmount <= 0) revert InvalidAmount();
        if (_initialPrice <= 0) revert InvalidPrice();
        if (_durationInSeconds <= 0) revert InvalidDuration();
        if (_priceDecreaseRate <= 0) revert InvalidRate();

        uint256 totalPriceDecrease = _durationInSeconds * _priceDecreaseRate;
        require(
            totalPriceDecrease < _initialPrice,
            "Price would decrease below zero"
        );

        IERC20 token = IERC20(_tokenAddress);
        require(
            token.transferFrom(msg.sender, address(this), _tokenAmount),
            "Token transfer failed"
        );

        uint256 auctionId = nextAuctionId;
        nextAuctionId++;

        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + _durationInSeconds;

        auctions[auctionId] = Auction({
            seller: msg.sender,
            tokenAddress: _tokenAddress,
            tokenAmount: _tokenAmount,
            initialPrice: _initialPrice,
            priceDecreaseRate: _priceDecreaseRate,
            startTime: startTime,
            endTime: endTime,
            isActive: true,
            isSold: false
        });

        emit AuctionCreated(
            auctionId,
            msg.sender,
            _tokenAddress,
            _tokenAmount,
            _initialPrice,
            startTime,
            endTime
        );

        return auctionId;
    }

    function getCurrentPrice(uint256 _auctionId) public view returns (uint256) {
        Auction storage auction = auctions[_auctionId];
        if (auction.isActive != true) revert InActiveAuction();

        if (block.timestamp >= auction.endTime) {
            return
                auction.initialPrice -
                (auction.priceDecreaseRate *
                    (auction.endTime - auction.startTime)); //not certain of the calculaution
        }

        uint256 timeElapsed = block.timestamp - auction.startTime;
        uint256 priceDecrease = timeElapsed * auction.priceDecreaseRate;

        if (priceDecrease >= auction.initialPrice) {
            return 0;
        }

        return auction.initialPrice - priceDecrease;
    }

    function executeSwap(uint256 _auctionId) external payable {
        Auction storage auction = auctions[_auctionId];
        if (auction.isActive != true) revert InActiveAuction();
        if (auction.isSold != false) revert AlreadySold();
        if (block.timestamp >= auction.endTime) revert AuctionEnded();

        uint256 currentPrice = getCurrentPrice(_auctionId);
        require(msg.value >= currentPrice, "Insufficient payment");

        auction.isActive = false;
        auction.isSold = true;

        IERC20 token = IERC20(auction.tokenAddress);
        require(
            token.transfer(msg.sender, auction.tokenAmount),
            "Token transfer failed"
        );

        (bool sent, ) = auction.seller.call{value: currentPrice}("");
        require(sent, "Failed to send ETH to seller");

        uint256 excess = msg.value - currentPrice;
        if (excess > 0) {
            (bool refunded, ) = msg.sender.call{value: excess}("");
            require(refunded, "Failed to refund excess");
        }

        emit AuctionExecuted(_auctionId, msg.sender, currentPrice);
    }

    function cancelAuction(uint256 _auctionId) external {
        Auction storage auction = auctions[_auctionId];

        if (auction.seller != msg.sender) revert Unauthorized();
        if (auction.isActive != true) revert InActiveAuction();
        if (auction.isSold != false) revert AlreadySold();

        auction.isActive = false;

        IERC20 token = IERC20(auction.tokenAddress);
        require(
            token.transfer(auction.seller, auction.tokenAmount),
            "Token transfer failed"
        );

        emit AuctionCancelled(_auctionId);
    }

    function getAuctionInfo(
        uint256 _auctionId
    )
        external
        view
        returns (
            address seller,
            address tokenAddress,
            uint256 tokenAmount,
            uint256 initialPrice,
            uint256 currentPrice,
            uint256 startTime,
            uint256 endTime,
            bool isActive,
            bool isSold
        )
    {
        Auction storage auction = auctions[_auctionId];
        return (
            auction.seller,
            auction.tokenAddress,
            auction.tokenAmount,
            auction.initialPrice,
            getCurrentPrice(_auctionId),
            auction.startTime,
            auction.endTime,
            auction.isActive,
            auction.isSold
        );
    }
}
