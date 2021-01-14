//
//  AimpleSignalSwiftEncryptionAPIErrors.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 19/12/2020.
//

import Foundation

public enum SSAPIProtocolAddressError: LocalizedError {
    case incorrectNumberOfComponents, deviceIdIsNotInt, failedIntialisation
}

extension SSAPIProtocolAddressError {
    public var errorDescription: String? {
        switch self {
        case .incorrectNumberOfComponents:
            return NSLocalizedString("The wrong number of components were provided in the constructor", comment: "")
        case .deviceIdIsNotInt:
            return NSLocalizedString("The device ID provided was not in Int form", comment: "")
        case .failedIntialisation:
            return NSLocalizedString("Unable to intialise device address", comment: "")
        }
    }
}

public enum SSAPIEncryptionError: String, LocalizedError, Codable {
    case invalidUrl, badFormat, badResponseFromServer, serverError, requestThrottled, deviceExists, recipientUserDoesNotExist, recipientUserHasNoRegisteredDevice, recipientsDeviceChanged, sendersDeviceChanged, senderHasNoRegisteredDevice, unableToDecrypt, invalidSenderAddress, noStore, userHasNoRegisteredDevice, userDeviceChanged, unableToCreateKeys, reachedMaxPreKeys, prekeyIdExists, deviceChanged, userHasNoDevice, unableToGetPreKeyStatus, timeout, alteredIdentity
}
extension SSAPIEncryptionError {
    public var errorDescription: String? {
        switch self {
        case .invalidUrl:
            return NSLocalizedString("The server address provided is invalid", comment: "")
        case .badFormat:
            return NSLocalizedString("The values you provided were in the wrong format", comment: "")
        case .badResponseFromServer:
            return NSLocalizedString("The response from the server was invalid", comment: "")
        case .serverError:
            return NSLocalizedString("The server returned an error", comment: "")
        case .requestThrottled:
            return NSLocalizedString("The request was throttled", comment: "")
        case .deviceExists:
            return NSLocalizedString("A device already exists on the server", comment: "")
        case .recipientUserDoesNotExist:
            return NSLocalizedString("The specified user does not exist", comment: "")
        case .recipientUserHasNoRegisteredDevice:
            return NSLocalizedString("The recipient user does not have a registered device", comment: "")
        case .recipientsDeviceChanged:
            return NSLocalizedString("The recipients device has changed", comment: "")
        case .sendersDeviceChanged:
            return NSLocalizedString("The sending user's device has changed", comment: "")
        case .senderHasNoRegisteredDevice:
            return NSLocalizedString("The sending user has no registered device", comment: "")
        case .unableToDecrypt:
            return NSLocalizedString("Unable to decrypt message", comment: "")
        case .invalidSenderAddress:
            return NSLocalizedString("The senders address was in an incorrect format", comment: "")
        case .noStore:
            return NSLocalizedString("There was an error loading your encryption data", comment: "")
        case .userHasNoRegisteredDevice:
            return NSLocalizedString("You have not registered a device", comment: "")
        case .userDeviceChanged:
            return NSLocalizedString("Your device has changed", comment: "")
        case .unableToCreateKeys:
            return NSLocalizedString("Unable to create new pre keys", comment: "")
        case .reachedMaxPreKeys:
            return NSLocalizedString("Tried to create too many prekeys", comment: "")
        case .prekeyIdExists:
            return NSLocalizedString("Tried to create an existing prekey", comment: "")
        case .deviceChanged:
            return NSLocalizedString("Your device has changed", comment: "")
        case .userHasNoDevice:
            return NSLocalizedString("You have not registered a device", comment: "")
        case .unableToGetPreKeyStatus:
            return NSLocalizedString("Unable to count the number of prekeys in the store", comment: "")
        case .timeout:
            return NSLocalizedString("The request timed out. Please try again.", comment: "")
        case .alteredIdentity:
            return NSLocalizedString("The sender's identity has changed.", comment: "")
        }
    }
}
