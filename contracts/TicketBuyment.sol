//SPDX-License-Identifier: LGPL-3.0-or.later

pragma solidity >0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";

contract TicketBuyment is Ownable {
    struct Ticket {
        uint price;
        bool sold;
    }

    mapping(uint256 => Ticket) train;
    mapping(address => uint256[]) buyerts;

    uint public value;
    uint public amount;
    uint256[] tickets;

    //error OutOfTickets();
    error WrongSum();

    event SellerRefunded();

    constructor(uint256 _amount, uint _price) payable { //60, 12 => 720 => 360
        amount = _amount;
        for (uint256 i = 0; i < amount; i++)
            train[i+1] = Ticket(_price, false);
    }

    function buyTickets(uint256[] memory seats)  //2, 15 => 30
        payable
        external
    {
        for (uint256 i = 0; i < seats.length; i++)
            value += train[seats[i]].price;
        if (value != msg.value)
            revert WrongSum();
        refundSeller();
        for (uint256 i = 0; i < seats.length; i++) {
            train[seats[i]].sold = true;
        }
        buyerts[msg.sender] = seats;
    }

    function getTickets(address client) external view returns(uint256[] memory) {
        return (buyerts[client]);
    }

    function checkIfFree(uint256 ticket) external view returns(bool) {
        return train[ticket].sold;   
    }

    function refundSeller() internal
    {
        emit SellerRefunded();
        payable(owner()).transfer(value);
        value = 0;
    }
}