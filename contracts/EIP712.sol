//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "./interfaces/IManagement.sol";
import "./interfaces/IFactory.sol";
import "./interfaces/IProperty.sol";

contract EIP712 is EIP712Upgradeable, OwnableUpgradeable {
    using ECDSAUpgradeable for bytes32;

    /**
        @dev Precalculate typehashes:
            - CANCELLATION_POLICY_TYPEHASH = keccak256("CancellationPolicy(uint256 expireAt,uint256 refundAmount)")
                                           = 0x71ed7adc2b3cc6f42e80ad08652651cbc6e0fd93b50d04298efafcfb6570f246
            
            - BOOKING_SETTING_TYPEHASH     = keccak256("Msg(uint256 bookingId,uint256 checkIn,uint256 checkOut,uint256 expireAt,uint256 bookingAmount,address paymentToken,address referrer,address guest,CancellationPolicy[] policies)CancellationPolicy(uint256 expireAt,uint256 refundAmount)");
                                           = 0x4299a080339bf90a75c045ad1230a6e716fe5314d953e0dcca074f146cfd96a5
     */

    IManagement public management;

    function init(address _management) external initializer {
        __Ownable_init();
        __EIP712_init("DtravelBooking", "1");

        management = IManagement(_management);
    }

    /**
        @notice Verify typed ethereum message for booking using EIP712
        @dev Caller must be property contract
        @param _propertyId property id
        @param _setting    booking setting
        @param _signature  signed message following EIP712
     */
    function verify(
        uint256 _propertyId,
        IProperty.BookingSetting calldata _setting,
        bytes calldata _signature
    ) external {
        require(
            _msgSender() ==
                IFactory(management.factory()).property(_propertyId),
            "Unauthorized"
        );

        uint256 n = _setting.policies.length;
        bytes32[] memory policiesHashes = new bytes32[](n);
        for (uint256 i; i < n; i++) {
            policiesHashes[i] = keccak256(
                abi.encode(
                    0x71ed7adc2b3cc6f42e80ad08652651cbc6e0fd93b50d04298efafcfb6570f246,
                    _setting.policies[i].expireAt,
                    _setting.policies[i].refundAmount
                )
            );
        }

        address signer = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    0x4299a080339bf90a75c045ad1230a6e716fe5314d953e0dcca074f146cfd96a5,
                    _setting.bookingId,
                    _setting.checkIn,
                    _setting.checkOut,
                    _setting.expireAt,
                    _setting.bookingAmount,
                    _setting.paymentToken,
                    _setting.referrer,
                    _msgSender(),
                    keccak256(abi.encodePacked(policiesHashes))
                )
            )
        ).recover(_signature);
        require(signer == management.verifier(), "InvalidSignature");
    }
}