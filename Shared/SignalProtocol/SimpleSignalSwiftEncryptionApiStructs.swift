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
    var created: Int
    var content: String
    var senderRegistrationId: Int
    var senderAddress: String
}

public struct SSAPIGetMessagesOutput {
    var message: String
    var senderAddress: ProtocolAddress
}

public enum SSAPIDeleteMessageOutcome {
    case messageDeleted, notMessageOwner, nonExistantMessage, serverError
}
