//
//  RootView.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 05/12/2020.
//

import Foundation

class AppState: ObservableObject {
    @Published var loggedInUser: LoggedInUser? = nil
    @Published var displayedError: IdentifiableError? = nil
}
