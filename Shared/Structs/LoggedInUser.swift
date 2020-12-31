//
//  LoggedInUser.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 06/12/2020.
//

import Foundation

public class LoggedInUser: Equatable, Hashable, Codable {
    
    public let userName: String
    public var deviceId: Int? {
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
    @Published public var subscriptionExpiryDate: Date? = nil {
        didSet {
            handleStoreObject()
        }
    }
    
    enum CodingKeys: CodingKey {
        case userName, deviceId, serverAddress, authCode, is2FAUser, subscriptionExpiryDate
    }

    
    var combinedName: String {
        return "\(self.userName):\(self.deviceId ?? -1):\(String(describing: self.serverAddress.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed))):\(self.authCode):\(self.is2FAUser ? "true" : "false"):\(self.subscriptionExpiryDate?.timeIntervalSince1970 ?? -1)"
    }
    
    public init(userName: String, deviceId: Int? = nil, serverAddress: String, authCode: String, is2FAUser: Bool, subscriptionExpiryDate: Date? = nil) {
        self.userName = userName
        self.deviceId = deviceId
        self.serverAddress = serverAddress
        self.authCode = authCode
        self.is2FAUser = is2FAUser
        self.subscriptionExpiryDate = subscriptionExpiryDate
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userName = try container.decode(String.self, forKey: .userName)
        deviceId = try container.decodeIfPresent(Int.self, forKey: .deviceId)
        serverAddress = try container.decode(String.self, forKey: .serverAddress)
        authCode = try container.decode(String.self, forKey: .authCode)
        is2FAUser = try container.decode(Bool.self, forKey: .is2FAUser)
        subscriptionExpiryDate = try container.decodeIfPresent(Date.self, forKey: .subscriptionExpiryDate)
    }
    
    
    public init(combinedName: String) throws {
        let components = combinedName.components(separatedBy: ":")
        guard components.count == 6 else {throw LoggedInUserError.invalidCombinedName}
        self.userName = components[0]
        // Note -1 codes deviceId = nil
        self.deviceId = Int(components[1]) == -1 ? nil : Int(components[1])
        self.serverAddress = components[2]
        self.authCode = String(components[3]).removingPercentEncoding!
        self.is2FAUser = (components[4] == "true") ? true : false
        if Int(components[5]) == -1 {
            self.subscriptionExpiryDate = nil
        } else {
            guard let subscriptionExpiryTimeInterval = Double(components[5]) else {
                throw LoggedInUserError.invalidCombinedName
            }
            self.subscriptionExpiryDate = Date(timeIntervalSince1970: subscriptionExpiryTimeInterval)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userName, forKey: .userName)
        try container.encode(deviceId, forKey: .deviceId)
        try container.encode(serverAddress, forKey: .serverAddress)
        try container.encode(authCode, forKey: .authCode)
        try container.encode(is2FAUser, forKey: .is2FAUser)
        try container.encode(subscriptionExpiryDate, forKey: .subscriptionExpiryDate)
    }
    
    
    public static func == (lhs: LoggedInUser, rhs: LoggedInUser) -> Bool {
        return lhs.combinedName == rhs.combinedName
    }
    
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(userName)
        hasher.combine(deviceId)
        hasher.combine(serverAddress)
        hasher.combine(authCode)
        hasher.combine(is2FAUser ? "true" : "false")
        hasher.combine(subscriptionExpiryDate)
    }
    
    private func handleStoreObject() {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(self) else {
            print("Error encoding object, unable to save user")
            return
        }
        KeychainSwift().set(data, forKey: "loggedInUser")
    }
    
    private func handleAddObservers() {
        let notificationCentre = NotificationCenter.default
        notificationCentre.addObserver(self,
                                       selector: #selector(self.handleSubscriptionVerified(_:)),
                                       name: .subscriptionController_SubscriptionVerified,
                                       object: nil)
        notificationCentre.addObserver(self,
                                       selector: #selector(self.handleSubscriptionFailed(_:)),
                                       name: .subscriptionController_SubscriptionFailed,
                                       object: nil)
    }
    
    @objc private func handleSubscriptionVerified(_ notification: NSNotification) {
        guard let expiryDate = notification.userInfo?["expiry"] as? Date else {
            print("No expiry date found in Subscription Verified Notification")
            return
        }
        self.subscriptionExpiryDate = expiryDate
    }
    
    @objc private func handleSubscriptionFailed(_ notification: NSNotification) {
        self.subscriptionExpiryDate = nil
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
