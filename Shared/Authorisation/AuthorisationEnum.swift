//
//  AuthorisationEnum.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 06/12/2020.
//

import Foundation

public enum loginOutcome {
    case success
    case twoFactorRequired(String)
    case failure
}
