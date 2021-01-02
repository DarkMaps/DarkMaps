//
//  AimpleSignalSwiftEncryptionApiStructs.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 19/12/2020.
//

import Foundation

public struct SSAPIPreKeyBundleResponse: Codable {
    var address: String
    var identityKey: String
    var registrationId: UInt32
    var preKey: SSAPIReceivedPreKey
    var signedPreKey: SSAPIReceivedSignedPreKey
}

public struct SSAPIReceivedPreKey: Codable {
    var keyId: UInt32
    var publicKey: String
}

public struct SSAPIReceivedSignedPreKey: Codable {
    var keyId: UInt32
    var publicKey: String
    var signature: String
}

public struct SSAPIGetMessagesResponse: Codable {
    var id: Int
    var content: String
    var recipientAddress: String
    var senderRegistrationId: Int
    var senderAddress: String
}

public struct SSAPIGetMessagesContent: Codable {
    var registrationId: Int
    var content: String
}

public struct SSAPIGetMessagesOutput {
    var id: Int
    var error: SSAPIEncryptionError? = nil
    var message: String? = nil
    var senderAddress: ProtocolAddress
}

public struct SSAPIGetDeviceOutput: Codable {
    var id: Int
    var user: Int
    var identityKey: String
    var registrationId: Int
    var address: String
}

public enum SSAPIDeleteMessageOutcome {
    case messageDeleted, notMessageOwner, nonExistantMessage, serverError
}
