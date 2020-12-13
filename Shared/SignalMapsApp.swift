//
//  SignalMapsApp.swift
//  Shared
//
//  Created by Matthew Roche on 28/11/2020.
//

import SwiftUI

@main
struct SignalMapsApp: App {
    var appState = AppState()
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(appState)
        }
    }
}
