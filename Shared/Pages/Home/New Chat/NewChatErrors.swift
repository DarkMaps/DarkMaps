//
//  NewChatErrors.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 28/12/2020.
//

import Foundation

public enum NewChatErrors: LocalizedError {
    case noUserLoggedIn
}

extension NewChatErrors {
    public var errorDescription: String? {
        switch self {
        case .noUserLoggedIn:
            return NSLocalizedString("There is no user logged in.", comment: "")
        }
    }
}
