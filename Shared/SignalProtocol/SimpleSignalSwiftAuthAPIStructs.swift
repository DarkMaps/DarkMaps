//
//  SimpleSignalSwiftAPIStructs.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 17/12/2020.
//

import Foundation

public struct SSAPILoginResponse: Codable {
    var authToken: String
}

public struct SSAPISubmit2FAResponse: Codable {
    var authToken: String
}

public struct SSAPIActivate2FAResponse: Codable {
    var message: String?
    var qrLink: String?
}

public struct SSAPIConfirm2FAResponse: Codable {
    var backupCodes: [String]
}
