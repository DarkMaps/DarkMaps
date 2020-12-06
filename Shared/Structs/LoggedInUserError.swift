//
//  LoggedInUserError.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 06/12/2020.
//

import Foundation

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
