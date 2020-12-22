//
//  AimpleSignalSwiftEncryptionAPIErrors.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 19/12/2020.
//

import Foundation

public enum SSAPIProtocolAddressError: LocalizedError {
    case incorrectNumberOfComponents, deviceIdIsNotInt
}

public enum SSAPIEncryptionError: LocalizedError {
    case invalidUrl, badFormat, badResponseFromServer, serverError, requestThrottled, deviceExists, recipientUserDoesNotExist, recipientUserHasNoRegisteredDevice, recipientsDeviceChanged, sendersDeviceChanged, senderHasNoRegisteredDevice, unableToDecrypt, invalidSenderAddress, noStore, userHasNoRegisteredDevice, userDeviceChanged, unableToCreateKeys, reachedMaxPreKeys, prekeyIdExists, deviceChanged, userHasNoDevice, unableToGetPreKeyStatus
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
        }
    }
}

public enum SSAPIEncryptionUploadDeviceError: LocalizedError {
    case invalidUrl, badFormat, badResponseFromServer, serverError, requestThrottled, deviceExists
}

extension SSAPIEncryptionUploadDeviceError {
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
        }
    }
}


public enum SSAPIEncryptionSendMessageError: LocalizedError {
    case noStore, invalidUrl, badFormat, badResponseFromServer, serverError, requestThrottled, recipientUserDoesNotExist, recipientUserHasNoRegisteredDevice, recipientsDeviceChanged, sendersDeviceChanged, senderHasNoRegisteredDevice
}

extension SSAPIEncryptionSendMessageError {
    public var errorDescription: String? {
        switch self {
        case .noStore:
            return NSLocalizedString("There was an error loading your encryption data", comment: "")
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
        }
    }
}

public enum SSAPIEncryptionGetMessagesError: LocalizedError {
    case noStore, invalidUrl, badFormat, badResponseFromServer, serverError, requestThrottled, userHasNoRegisteredDevice, userDeviceChanged, unableToDecrypt, invalidSenderAddress
}

extension SSAPIEncryptionGetMessagesError {
    public var errorDescription: String? {
        switch self {
        case .noStore:
            return NSLocalizedString("There was an error loading your encryption data", comment: "")
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
        case .userHasNoRegisteredDevice:
            return NSLocalizedString("You have not registered a device", comment: "")
        case .userDeviceChanged:
            return NSLocalizedString("Your device has changed", comment: "")
        case .unableToDecrypt:
            return NSLocalizedString("Unable to decrypt message", comment: "")
        case .invalidSenderAddress:
            return NSLocalizedString("The senders address was in an incorrect format", comment: "")
        }
    }
}


public enum SSAPIEncryptionDeleteDeviceError: LocalizedError {
    case noStore, invalidUrl, badFormat, badResponseFromServer, serverError, requestThrottled, userHasNoRegisteredDevice
}

extension SSAPIEncryptionDeleteDeviceError {
    public var errorDescription: String? {
        switch self {
        case .noStore:
            return NSLocalizedString("There was an error loading your encryption data", comment: "")
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
        case .userHasNoRegisteredDevice:
            return NSLocalizedString("You have not registered a device", comment: "")
        }
    }
}

public enum SSAPIEncryptionDeleteMessagesError: LocalizedError {
    case noStore, invalidUrl, badFormat, badResponseFromServer, serverError, requestThrottled, userHasNoRegisteredDevice, userDeviceChanged
}

extension SSAPIEncryptionDeleteMessagesError {
    public var errorDescription: String? {
        switch self {
        case .noStore:
            return NSLocalizedString("There was an error loading your encryption data", comment: "")
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
        case .userHasNoRegisteredDevice:
            return NSLocalizedString("You have not registered a device", comment: "")
        case .userDeviceChanged:
            return NSLocalizedString("Your device has changed", comment: "")
        }
    }
}


public enum SSAPIEncryptionUpdatePrekeyError: LocalizedError {
    case noStore, invalidUrl, badFormat, badResponseFromServer, serverError, requestThrottled, userHasNoRegisteredDevice, unableToCreateKeys, reachedMaxPreKeys, prekeyIdExists, deviceChanged, userHasNoDevice, unableToGetPreKeyStatus
}

extension SSAPIEncryptionUpdatePrekeyError {
    public var errorDescription: String? {
        switch self {
        case .noStore:
            return NSLocalizedString("There was an error loading your encryption data", comment: "")
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
        case .userHasNoRegisteredDevice:
            return NSLocalizedString("You have not registered a device", comment: "")
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
        }
    }
}

public enum SSAPIEncryptionUpdateSignedPrekeyError: LocalizedError {
    case noStore, invalidUrl, badFormat, badResponseFromServer, serverError, requestThrottled, userHasNoRegisteredDevice, unableToCreateKeys, reachedMaxPreKeys, prekeyIdExists, deviceChanged, userHasNoDevice, unableToGetPreKeyStatus
}

extension SSAPIEncryptionUpdateSignedPrekeyError {
    public var errorDescription: String? {
        switch self {
        case .noStore:
            return NSLocalizedString("There was an error loading your encryption data", comment: "")
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
        case .userHasNoRegisteredDevice:
            return NSLocalizedString("You have not registered a device", comment: "")
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
        }
    }
}
