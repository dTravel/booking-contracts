// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./DtravelProperty.sol";

contract DtravelFactory is Ownable {
    address public configContract;
    mapping(address => bool) private propertyMapping;

    event PropertyCreated(uint256[] ids, address[] properties, address host);
    event Book(address property, uint256 bookingId, uint256 bookedTimestamp);
    event Cancel(
        address property,
        uint256 bookingId,
        uint256 guestAmount,
        uint256 hostAmount,
        uint256 treasuryAmount,
        uint256 cancelTimestamp
    );
    event Payout(
        address property,
        uint256 bookingId,
        uint256 hostAmount,
        uint256 treasuryAmount,
        uint256 payoutTimestamp
    );

    constructor(address _config) {
        configContract = _config;
    }

    function deployProperty(uint256[] memory _ids, address _host) public onlyOwner {
        require(_ids.length > 0, "Invalid property ids");
        require(_host != address(0), "Host address is invalid");
        address[] memory properties;
        for (uint256 i = 0; i < _ids.length; i++) {
            DtravelProperty property = new DtravelProperty(_ids[i], configContract, address(this), _host);
            propertyMapping[address(property)] = true;
            properties[i] = address(property);
        }
        emit PropertyCreated(_ids, properties, _host);
    }

    function book(uint256 _bookingId) external {
        require(propertyMapping[msg.sender] == true, "Property not found");
        emit Book(msg.sender, _bookingId, block.timestamp);
    }

    function cancel(
        uint256 _bookingId,
        uint256 _guestAmount,
        uint256 _hostAmount,
        uint256 _treasuryAmount,
        uint256 _cancelTimestamp
    ) external {
        require(propertyMapping[msg.sender] == true, "Property not found");
        emit Cancel(msg.sender, _bookingId, _guestAmount, _hostAmount, _treasuryAmount, _cancelTimestamp);
    }

    function payout(
        uint256 _bookingId,
        uint256 _hostAmount,
        uint256 _treasuryAmount,
        uint256 _payoutTimestamp
    ) external {
        require(propertyMapping[msg.sender] == true, "Property not found");
        emit Payout(msg.sender, _bookingId, _hostAmount, _treasuryAmount, _payoutTimestamp);
    }
}