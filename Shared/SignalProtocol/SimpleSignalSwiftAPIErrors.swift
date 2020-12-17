//
//  SimpleSignalSwiftAPIErrors.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 17/12/2020.
//

import Foundation

public enum SSAPILoginError: Error {
    case invalidCredentials, invalidUrl, badFormat, badResponseFromServer, serverError, needsTwoFactorAuthentication(String), requestThrottled
}

extension SSAPILoginError {
    public var localizedDescription: String {
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
        case .needsTwoFactorAuthentication:
            return NSLocalizedString("This user has two factor authentication enabled", comment: "")
        }
    }
}



public enum SSAPIActivate2FAError: Error {
    case invalidUrl, badFormat, badResponseFromServer, serverError, possibleIncorrectMFAMethodName, requestThrottled
}

extension SSAPIActivate2FAError {
    public var localizedDescription: String {
        switch self {
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
        case .possibleIncorrectMFAMethodName:
            return NSLocalizedString("This type of two factor authentication does not exist on the server", comment: "")
        }
    }
}

