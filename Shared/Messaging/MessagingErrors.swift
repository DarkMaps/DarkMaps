//
//  MessagingErrors.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 26/12/2020.
//

import Foundation

enum MessageStoreError: LocalizedError {
    case noMessageFromThisSender, poorlyFormattedMessageData, poorlyFormattedLiveMessageArrayData, liveMessageRecipientAlreadyExists, liveMessageRecipientDoesNotExist
}

extension MessageStoreError {
    public var errorDescription: String? {
        switch self {
        case .noMessageFromThisSender:
            return NSLocalizedString("There is no message stored from this sender.", comment: "")
        case .poorlyFormattedMessageData:
            return NSLocalizedString("The message stored for this user has been corrupted and will be deleted.", comment: "")
        case .liveMessageRecipientAlreadyExists:
            return NSLocalizedString("This live message recipient already exists.", comment: "")
        case .poorlyFormattedLiveMessageArrayData:
            return NSLocalizedString("The stored live message recipient array was poorly formatted.", comment: "")
        case .liveMessageRecipientDoesNotExist:
            return NSLocalizedString("The recipient you asked to update does not exist.", comment: "")
        }
    }
}

enum MessagingControllerError: String, LocalizedError, Codable {
    case unableToStoreMessages, unableToRetrieveMessages, unableToDecryptMessage, poorlyFormattedLocation, unableToDeleteMessage, unableToUpdateDeviceKeys, unableToCreateAddress, unableToCreateEncryptionHandler, unableToCreateMessagingStore, noDeviceCreated, unableToSendMessage, unableToDeleteDevice, unableToCreateDevice, needToProvideUsername, remoteDeviceExists, poorlyFormattedLiveMessageArrayData, liveMessageRecipientAlreadyExists, noDeviceOnServer, alteredIdentity, unableToUpdateIdentity, remoteDeviceChanged, unauthorised, recipientUserDoesNotExist, recipientUserHasNoRegisteredDevice
}

extension MessagingControllerError {
    public var errorDescription: String? {
        switch self {
        case .recipientUserHasNoRegisteredDevice:
            return NSLocalizedString("This user does not have a device registered on our servers.", comment: "")
        case .recipientUserDoesNotExist:
            return NSLocalizedString("This user does not exist.", comment: "")
        case .noDeviceOnServer:
            return NSLocalizedString("There is no device stored on the server, logging out.", comment: "")
        case .remoteDeviceExists:
            return NSLocalizedString("A device already exists on the server.", comment: "")
        case .needToProvideUsername:
            return NSLocalizedString("Unable to delete device without userName as no device created locally yet.", comment: "")
        case .unableToCreateDevice:
            return NSLocalizedString("Unable to create device.", comment: "")
        case .unableToDeleteDevice:
            return NSLocalizedString("Unable to delete device.", comment: "")
        case .unableToSendMessage:
            return NSLocalizedString("Unable to send message.", comment: "")
        case .noDeviceCreated:
            return NSLocalizedString("No device has been created yet.", comment: "")
        case .unableToCreateMessagingStore:
            return NSLocalizedString("Unable to set up store for messages.", comment: "")
        case .unableToCreateEncryptionHandler:
            return NSLocalizedString("Unable to set up encryption.", comment: "")
        case .unableToCreateAddress:
            return NSLocalizedString("Unable to create address for user.", comment: "")
        case .unableToStoreMessages:
            return NSLocalizedString("Unable to store the messages received.", comment: "")
        case .unableToRetrieveMessages:
            return NSLocalizedString("Unable to retrieve messages from the server.", comment: "")
        case .unableToDecryptMessage:
            return NSLocalizedString("The message received could not be decrypted.", comment: "")
        case .poorlyFormattedLocation:
            return NSLocalizedString("The location provided was incorrectly formatted.", comment: "")
        case .unableToDeleteMessage:
            return NSLocalizedString("There was an error whilst trying to delete the messages we just received.", comment: "")
        case .unableToUpdateDeviceKeys:
            return NSLocalizedString("There was an error while trying to update the device keys.", comment: "")
        case .liveMessageRecipientAlreadyExists:
            return NSLocalizedString("This live message recipient already exists.", comment: "")
        case .poorlyFormattedLiveMessageArrayData:
            return NSLocalizedString("The stored live message recipient array was poorly formatted.", comment: "")
        case .alteredIdentity:
            return NSLocalizedString("The sender's idenity has altered", comment: "")
        case .unableToUpdateIdentity:
            return NSLocalizedString("An error occured whilst updating this user's identity", comment: "")
        case .remoteDeviceChanged:
            return NSLocalizedString("The device on the server has changed", comment: "")
        case .unauthorised:
            return NSLocalizedString("You have been logged out by the server.", comment: "")
        }
    }
}
