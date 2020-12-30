//
//  ListViewErrors.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 28/12/2020.
//

import Foundation

public enum ListViewErrors: LocalizedError {
    case noUserLoggedIn, unableToRetrieveMessages
}

extension ListViewErrors {
    var localisedDescription: String? {
        switch self {
        case .noUserLoggedIn:
            return NSLocalizedString("There is no user logged in.", comment: "")
        case .unableToRetrieveMessages:
            return NSLocalizedString("There was a problem retrieving the stored messages.", comment: "")
        }
    }
}
