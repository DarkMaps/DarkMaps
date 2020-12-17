//
//  AuthorisationError.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 06/12/2020.
//

import Foundation

public enum AuthorisationError: LocalizedError {
    case invalidCredentials
    case invalidUrl
    case badFormat
    case badResponseFromServer
    case serverError
    case requestThrottled
}

extension AuthorisationError {
    public var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return NSLocalizedString("The credentials provided are invalid", comment: "")
        case .invalidUrl:
            return NSLocalizedString("The server address provided is invalid", comment: "")
        case .badFormat:
            return NSLocalizedString("The values you provided were in the wrong format", comment: "")
        case .badResponseFromServer:
            return NSLocalizedString("The response from the server was invalid", comment: "")
        case .serverError:
            return NSLocalizedString("The server returned an error", comment: "")
        case .requestThrottled:
            return NSLocalizedString("The request was throttled", comment: "")
        }
    }
}

public enum TwoFactorError: LocalizedError {
    case invalidMFAName
    case invalidUrl
    case badFormat
    case badResponseFromServer
    case serverError
    case requestThrottled
}

extension TwoFactorError {
    public var errorDescription: String? {
        switch self {
        case .invalidMFAName:
            return NSLocalizedString("This type of two factor authentication does not exist on the server", comment: "")
        case .invalidUrl:
            return NSLocalizedString("The server address provided is invalid", comment: "")
        case .badFormat:
            return NSLocalizedString("The values you provided were in the wrong format", comment: "")
        case .badResponseFromServer:
            return NSLocalizedString("The response from the server was invalid", comment: "")
        case .serverError:
            return NSLocalizedString("The server returned an error", comment: "")
        case .requestThrottled:
            return NSLocalizedString("The request was throttled", comment: "")
        }
    }
}
