//SPDX-License-Identifier: LGPL-3.0-or.later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TicketItem is ERC721Enumerable, Ownable {
    struct Ticket {
        uint256 seatNumber;
        address buyer;
    }

    mapping(uint256 => Ticket) tokenTickets;
    mapping(uint256 => bool) soldTickets;

    uint256 public leaveTime;
    uint public cost;
    uint256 public maxSupply;
    uint256 constant public maxMintAmount = 20;
    bool public sellsClosed = true;

    event TrainDeparture();

    modifier onlyBefore(uint256 _time) {
        require(block.timestamp < _time, "Train already leaved!");
        _;
    }

    modifier onlyAfter(uint256 _time) {
        require(block.timestamp > _time, "Train haven't departured or cancelled yet!");
        _;
    }

    constructor(
        uint256 _maxSupply,
        uint _cost,
        uint256 _time
    ) ERC721("TrainTicket", "TI") {
        maxSupply = _maxSupply;
        cost = _cost;
        leaveTime = _time;
    }

    function checkIfTicketSold(uint256 seat) external view returns(bool) {
        return soldTickets[seat];
    }

    function buyTickets(uint256[] memory seats) external payable onlyBefore(leaveTime) {
        uint256 supply = totalSupply();
        require(seats.length > 0, "Amount of mint cannot be less than 1!");
        require(seats.length <= maxMintAmount, "Mint amount is too big!");
        require(supply + seats.length <= maxSupply, "You exceeded max amount of NFTs!");

        require(msg.value >= cost * seats.length);

        for (uint256 i = 0; i < seats.length; i++) {
            require(!soldTickets[seats[i]], "This seat is not free!");
            require(seats[i] <= maxSupply, "No such tickets!");
            setTokenOnTicket(supply + i + 1, seats[i]);
            soldTickets[seats[i]] = true;
            _safeMint(msg.sender, supply + i + 1);
        }
    }

    function ticketsOfOwner(address _owner)
        public
        view
        returns(uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++)
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        return tokenIds;
    }

    function setTokenOnTicket(uint256 tokenId, uint256 seat) 
        private
        returns (Ticket memory)
    {
        Ticket memory ticket = Ticket(seat, msg.sender);
        tokenTickets[tokenId] = ticket;
        return ticket;
    }

    function getTokenOnTicket(uint256 tokenId) 
        external 
        view
        returns(Ticket memory) 
    {
        return tokenTickets[tokenId];
    } 

    function departTrain() external onlyOwner onlyAfter(leaveTime) {
        require(sellsClosed, "Sells have already closed!");
        sellsClosed = false;
        _refundSeller();
        emit TrainDeparture();
    }

    function _refundSeller() private {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Transaction withdraw failed!");
    }
}