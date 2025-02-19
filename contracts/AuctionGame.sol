// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DutchAuctionSwap {
    address public seller;
    IERC20 public token;
    uint256 public initialPrice;
    uint256 public startTime;
    uint256 public duration;
    uint256 public priceDecreaseRate;
    uint256 public tokensForSale;
    bool public auctionEnded;

    event AuctionStarted(
        address seller,
        uint256 initialPrice,
        uint256 duration,
        uint256 priceDecreaseRate
    );
    event TokenPurchased(address buyer, uint256 amount, uint256 price);

    constructor(address _token) {
        token = IERC20(_token);
    }

    function startAuction(
        uint256 _tokensForSale,
        uint256 _initialPrice,
        uint256 _duration
    ) external {
        require(!auctionEnded, "Auction already ended");
        require(
            token.transferFrom(msg.sender, address(this), _tokensForSale),
            "Token transfer failed"
        );

        seller = msg.sender;
        tokensForSale = _tokensForSale;
        initialPrice = _initialPrice;
        duration = _duration;
        startTime = block.timestamp;
        priceDecreaseRate = _initialPrice / _duration;
        auctionEnded = false;

        emit AuctionStarted(seller, initialPrice, duration, priceDecreaseRate);
    }

    function getCurrentPrice() public view returns (uint256) {
        uint256 elapsedTime = block.timestamp - startTime;
        if (elapsedTime >= duration) {
            return 0;
        }
        return initialPrice - (elapsedTime * priceDecreaseRate);
    }

    function buyTokens() external payable {
        require(!auctionEnded, "Auction has ended");
        uint256 currentPrice = getCurrentPrice();
        require(msg.value >= currentPrice, "Insufficient payment");

        auctionEnded = true;
        require(
            token.transfer(msg.sender, tokensForSale),
            "Token transfer failed"
        );
        payable(seller).transfer(msg.value);

        emit TokenPurchased(msg.sender, tokensForSale, currentPrice);
    }
}
