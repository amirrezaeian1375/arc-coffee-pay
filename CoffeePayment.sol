// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ArcCoffeePay {
    address public owner;
    
    // Coffee prices in USDC (assuming 18 decimals like ETH on Arc)
    uint256 public constant AMERICANO_PRICE = 5 ether;
    uint256 public constant CAPPUCCINO_PRICE = 8 ether;
    uint256 public constant LATTE_PRICE = 10 ether;

    // Track partial payments for each user
    mapping(address => uint256) public balances;

    // Events for "On-chain Messaging"
    event PaymentReceived(address indexed user, uint256 amount, uint256 totalBalance);
    event CoffeeOrdered(address indexed user, string coffeeName, uint256 timestamp);
    event InsufficientFunds(address indexed user, uint256 remainingAmount);

    constructor() {
        // The address you provided
        owner = 0x562639eAA3e16199F29206f3f57aD3daD5903ac4;
    }

    // Function to buy coffee
    // coffeeType: 1 = Americano, 2 = Cappuccino, 3 = Latte
    function buyCoffee(uint8 coffeeType) public payable {
        require(coffeeType >= 1 && coffeeType <= 3, "Invalid coffee type");
        
        uint256 price;
        string memory coffeeName;

        if (coffeeType == 1) {
            price = AMERICANO_PRICE;
            coffeeName = "Americano";
        } else if (coffeeType == 2) {
            price = CAPPUCCINO_PRICE;
            coffeeName = "Cappuccino";
        } else {
            price = LATTE_PRICE;
            coffeeName = "Latte Macchiato";
        }

        // Add current payment to user's pending balance
        balances[msg.sender] += msg.value;
        
        emit PaymentReceived(msg.sender, msg.value, balances[msg.sender]);

        // Check if total balance is enough
        if (balances[msg.sender] >= price) {
            uint256 change = balances[msg.sender] - price;
            balances[msg.sender] = 0; // Reset balance after successful purchase

            // Send payment to owner using .call (The modern way)
            (bool success, ) = payable(owner).call{value: price}("");
            require(success, "Transfer to owner failed");
            
            // Refund change if any
            if (change > 0) {
                (bool refundSuccess, ) = payable(msg.sender).call{value: change}("");
                require(refundSuccess, "Refund failed");
            }

            // Emit the success "Message" on-chain
            emit CoffeeOrdered(msg.sender, coffeeName, block.timestamp);
        } else {
            // Tell user how much more is needed
            uint256 remaining = price - balances[msg.sender];
            emit InsufficientFunds(msg.sender, remaining);
        }
    }

    // Function to withdraw all funds (only owner)
    function withdraw() public {
        require(msg.sender == owner, "Only owner can withdraw");
        (bool success, ) = payable(owner).call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }

    // To receive USDC directly
    receive() external payable {}
}
