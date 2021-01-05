//
//  SimpleSignalSwiftAPIErrors.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 17/12/2020.
//

import Foundation

public enum SSAPIAuthRegisterError: LocalizedError {
    case emailExists, invalidUrl, badFormat, badResponseFromServer, serverError, requestThrottled, loginError
}

extension SSAPIAuthRegisterError {
    public var errorDescription: String? {
        switch self {
        case .emailExists:
            return NSLocalizedString("A user with that email already exists", comment: "")
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
        case .loginError:
            return NSLocalizedString("You have registered but there was an error logging in. Try logging in.", comment: "")
        }
    }
}

public enum SSAPIAuthLoginError: LocalizedError {
    case invalidCredentials, invalidUrl, badFormat, badResponseFromServer, serverError, needsTwoFactorAuthentication(String), requestThrottled
}

extension SSAPIAuthLoginError {
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

public enum SSAPIAuthResetPasswordError: LocalizedError {
    case invalidUrl, badFormat, badResponseFromServer, serverError, requestThrottled
}

extension SSAPIAuthResetPasswordError {
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
        }
    }
}

public enum SSAPIAuthSubmit2FAError: LocalizedError {
    case invalidToken, invalidCode, invalidUrl, badFormat, badResponseFromServer, serverError, requestThrottled
}

extension SSAPIAuthSubmit2FAError {
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



public enum SSAPIAuthActivate2FAError: LocalizedError {
    case twoFactorAlreadyExists, invalidUrl, badFormat, badResponseFromServer, serverError, possibleIncorrectMFAMethodName, requestThrottled
}

extension SSAPIAuthActivate2FAError {
    public var errorDescription: String? {
        switch self {
        case .twoFactorAlreadyExists:
            return NSLocalizedString("Two factor authentication already exists", comment: "")
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

public enum SSAPIAuthConfirm2FAError: LocalizedError {
    case invalidUrl, badFormat, badResponseFromServer, serverError, possibleIncorrectMFAMethodName, requestThrottled, invalidAuthorisation, invalidCode
}

extension SSAPIAuthConfirm2FAError {
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

public enum SSAPIAuthDeactivate2FAError: LocalizedError {
    case invalidUrl, badFormat, badResponseFromServer, serverError, possibleIncorrectMFAMethodName, requestThrottled, invalidAuthorisation, invalidCode
}

extension SSAPIAuthDeactivate2FAError {
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

public enum SSAPIAuthLogOutError: LocalizedError {
    case invalidUrl, badFormat, badResponseFromServer, serverError, requestThrottled, invalidAuthorisation
}

extension SSAPIAuthLogOutError {
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

public enum SSAPIAuthDeleteUserAccountError: LocalizedError {
    case invalidPassword, invalidUrl, badFormat, badResponseFromServer, serverError, requestThrottled, invalidAuthorisation
}

extension SSAPIAuthDeleteUserAccountError {
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
