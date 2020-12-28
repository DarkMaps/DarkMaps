//
//  ListViewErrors.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 28/12/2020.
//

import Foundation

public enum ListViewErrors: LocalizedError {
    case noUserLoggedIn
}

extension ListViewErrors {
    var localisedDescription: String? {
        switch self {
        case .noUserLoggedIn:
            return NSLocalizedString("There is no user logged in.", comment: "")
        }
    }
}
