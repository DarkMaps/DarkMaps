//
//  AuthorisationEnum.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 06/12/2020.
//

import Foundation

public enum LoginOutcome {
    case success(LoggedInUser)
    case twoFactorRequired(String)
    case failure(SSAPILoginError)
}
