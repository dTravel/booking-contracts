//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "./interfaces/IFactory.sol";
import "./interfaces/IManagement.sol";
import "./interfaces/IProperty.sol";

error ZeroAddress();
error OnlyOperator();
error PropertyExisted();

contract Factory is IFactory, OwnableUpgradeable {
    // linked management instance
    IManagement public management;

    // the upgrage beacon address of property contracts
    address private propertyBeacon;

    // returns the deployed property address for a given ID
    mapping(uint256 => address) public property;

    function init(address _management, address _beacon) external initializer {
        if (_management == address(0)) revert ZeroAddress();
        if (_beacon == address(0)) revert ZeroAddress();

        __Ownable_init();
        management = IManagement(_management);
        propertyBeacon = _beacon;
    }

    /**
       @notice Create a new property for host
       @dev    Caller must be Operator
       @param _propertyId The given property ID
       @param _host Address of property's host
     */
    function createProperty(uint256 _propertyId, address _host)
        external
        override
        returns (address _property)
    {
        if (_msgSender() != management.operator()) revert OnlyOperator();
        if (_host == address(0)) revert ZeroAddress();
        if (property[_propertyId] != address(0)) revert PropertyExisted();

        BeaconProxy proxy = new BeaconProxy(
            propertyBeacon,
            abi.encodeWithSelector(
                IProperty.init.selector,
                _propertyId,
                _host,
                address(management)
            )
        );

        _property = address(proxy);
        property[_propertyId] = _property;

        emit NewProperty(_propertyId, _property, _host);
    }
}