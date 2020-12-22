//
//  AimpleSignalSwiftEncryptionApiStructs.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 19/12/2020.
//

import Foundation

public struct SSAPIPreKeyBundleResponse: Codable {
    var address: String
    var identityKey: [UInt8]
    var registrationId: UInt32
    var preKey: SSAPIReceivedPreKey
    var signedPreKey: SSAPIReceivedSignedPreKey
}

public struct SSAPIReceivedPreKey: Codable {
    var keyId: UInt32
    var publicKey: [UInt8]
}

public struct SSAPIReceivedSignedPreKey: Codable {
    var keyId: UInt32
    var publicKey: [UInt8]
    var signature: [UInt8]
}

public struct SSAPIGetMessagesResponse: Codable {
    var id: Int
    var created: Date
    var content: [UInt8]
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
