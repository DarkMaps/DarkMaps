//
//  LoggedInUser.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 06/12/2020.
//

import Foundation

public class LoggedInUser: Equatable, Hashable, Codable {
    
    public let userName: String
    public var deviceName: String? {
        didSet {
            handleStoreObject()
        }
    }
    public let serverAddress: String
    public let authCode: String
    public var is2FAUser: Bool {
        didSet {
            handleStoreObject()
        }
    }
    
    var combinedName: String {
        return "\(self.userName):\(self.deviceName ?? "Unknown"):\(String(describing: self.serverAddress.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed))):\(self.authCode)"
    }
    
    public init(userName: String, deviceName: String? = nil, serverAddress: String, authCode: String, is2FAUser: Bool) {
        self.userName = userName
        self.deviceName = deviceName
        self.serverAddress = serverAddress
        self.authCode = authCode
        self.is2FAUser = is2FAUser
    }
    
    
    public init(combinedName: String) throws {
        let components = combinedName.components(separatedBy: ":")
        guard components.count == 5 else {throw LoggedInUserError.invalidCombinedName}
        self.userName = components[0]
        self.deviceName = components[1] == "Unknown" ? nil : components[1]
        self.serverAddress = components[2]
        self.authCode = String(components[3]).removingPercentEncoding!
        self.is2FAUser = (components[4] == "true") ? true : false
    }
    
    
    public static func == (lhs: LoggedInUser, rhs: LoggedInUser) -> Bool {
        return lhs.combinedName == rhs.combinedName
    }
    
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(userName)
        hasher.combine(deviceName)
        hasher.combine(serverAddress)
        hasher.combine(authCode)
        hasher.combine(is2FAUser ? "true" : "false")
    }
    
    func handleStoreObject() {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(self) else {
            print("Error encoding object, unable to save user")
            return
        }
        KeychainSwift().set(data, forKey: "loggedInUser")
    }
}


enum LoggedInUserError: LocalizedError {
    case invalidCombinedName
}

extension LoggedInUserError {
    public var errorDescription: String? {
        switch self {
            case .invalidCombinedName:
                return NSLocalizedString("Error loading user", comment: "")
        }
    }
}
