//
//  AimpleSignalSwiftEncryptionAPIErrors.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 19/12/2020.
//

import Foundation

    
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
