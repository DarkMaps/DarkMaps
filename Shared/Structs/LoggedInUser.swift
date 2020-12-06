//
//  LoggedInUser.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 06/12/2020.
//

import Foundation

// A class defining a recipient and their device
public class LoggedInUser: Equatable, Hashable {
    
    public let userName: String
    public let deviceName: String
    public let serverAddress: String
    public let authCode: String
    
    var combinedName: String {
        return "\(self.userName):\(self.deviceName):\(String(describing: self.serverAddress.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed))):\(self.authCode)"
    }
    
    /// init
    /// Initialise from strings
    /// - Parameters:
    ///   - userName: The username fo the recipient
    ///   - deviceName: The deviceName of the recipient
    public init(userName: String, deviceName: String, serverAddress: String, authCode: String) {
        self.userName = userName
        self.deviceName = deviceName
        self.serverAddress = serverAddress
        self.authCode = authCode
    }
    
    
    /// init
    /// Initialise from a combined name
    /// - Parameter combinedName: The combined name to initialise from
    public init(combinedName: String) throws {
        let components = combinedName.components(separatedBy: ":")
        guard components.count == 4 else {throw LoggedInUserError.invalidCombinedName}
        self.userName = components[0]
        self.deviceName = components[1]
        self.serverAddress = components[2]
        self.authCode = String(components[3]).removingPercentEncoding!
    }
    
    // Conforming to Equatable
    public static func == (lhs: LoggedInUser, rhs: LoggedInUser) -> Bool {
        return lhs.combinedName == rhs.combinedName
    }
    
    // Conforming to hashable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(userName)
        hasher.combine(deviceName)
        hasher.combine(serverAddress)
        hasher.combine(authCode)
    }
}
