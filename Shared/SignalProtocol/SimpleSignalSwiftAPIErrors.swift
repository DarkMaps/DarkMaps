//
//  SimpleSignalSwiftAPIErrors.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 17/12/2020.
//

import Foundation

public enum SSAPILoginError: LocalizedError {
    case invalidCredentials, invalidUrl, badFormat, badResponseFromServer, serverError, needsTwoFactorAuthentication(String), requestThrottled
}

extension SSAPILoginError {
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
        case .needsTwoFactorAuthentication:
            return NSLocalizedString("This user has two factor authentication enabled", comment: "")
        }
    }
}

public enum SSAPISubmit2FAError: LocalizedError {
    case invalidToken, invalidCode, invalidUrl, badFormat, badResponseFromServer, serverError, requestThrottled
}

extension SSAPISubmit2FAError {
    public var errorDescription: String? {
        switch self {
        case .invalidToken:
            return NSLocalizedString("The ephemeral token provided was incorrect", comment: "")
        case .invalidCode:
            return NSLocalizedString("The 2FA code provided was incorrect", comment: "")
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



public enum SSAPIActivate2FAError: LocalizedError {
    case invalidUrl, badFormat, badResponseFromServer, serverError, possibleIncorrectMFAMethodName, requestThrottled
}

extension SSAPIActivate2FAError {
    public var errorDescription: String? {
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

public enum SSAPIConfirm2FAError: LocalizedError {
    case invalidUrl, badFormat, badResponseFromServer, serverError, possibleIncorrectMFAMethodName, requestThrottled, invalidAuthorisation, invalidCode
}

extension SSAPIConfirm2FAError {
    public var errorDescription: String? {
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
        case .invalidAuthorisation:
            return NSLocalizedString("The authorisation details provided were incorrect", comment: "")
        case .invalidCode:
            return NSLocalizedString("The 2FA code provided was incorrect", comment: "")
        }
        
    }
}

public enum SSAPIDeactivate2FAError: LocalizedError {
    case invalidUrl, badFormat, badResponseFromServer, serverError, possibleIncorrectMFAMethodName, requestThrottled, invalidAuthorisation, invalidCode
}

extension SSAPIDeactivate2FAError {
    public var errorDescription: String? {
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
        case .invalidAuthorisation:
            return NSLocalizedString("The authorisation details provided were incorrect", comment: "")
        case .invalidCode:
            return NSLocalizedString("The 2FA code provided was incorrect", comment: "")
        }
        
    }
}

public enum SSAPILogOutError: LocalizedError {
    case invalidUrl, badFormat, badResponseFromServer, serverError, requestThrottled, invalidAuthorisation
}

extension SSAPILogOutError {
    public var errorDescription: String? {
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
        case .invalidAuthorisation:
            return NSLocalizedString("The authorisation details provided were incorrect", comment: "")
        }
        
    }
}

public enum SSAPIDeleteUserAccountError: LocalizedError {
    case invalidPassword, invalidUrl, badFormat, badResponseFromServer, serverError, requestThrottled, invalidAuthorisation
}

extension SSAPIDeleteUserAccountError {
    public var errorDescription: String? {
        switch self {
        case .invalidPassword:
            return NSLocalizedString("The current password provided was invalid", comment: "")
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
        case .invalidAuthorisation:
            return NSLocalizedString("The authorisation details provided were incorrect", comment: "")
        }
        
    }
}
