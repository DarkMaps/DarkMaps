//
//  AuthorisationError.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 06/12/2020.
//

import Foundation

enum AuthorisationError: LocalizedError {
    case invalidUsername
    case invalidPassword
}

extension AuthorisationError {
    public var errorDescription: String? {
        switch self {
            case .invalidUsername:
                return NSLocalizedString("The provided username is invalid", comment: "")
            case .invalidPassword:
                return NSLocalizedString("The provided password is invalid", comment: "")
        }
    }
}
