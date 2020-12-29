//
//  SignalMapsApp.swift
//  Shared
//
//  Created by Matthew Roche on 28/11/2020.
//

// https://peterfriese.dev/ultimate-guide-to-swiftui2-application-lifecycle/

import SwiftUI

@main
struct SignalMapsApp: App {
    
    @StateObject private var appState = AppState()
    
    func handleInit() {
        let decoder = JSONDecoder()
        guard let storedUserData = KeychainSwift().getData("loggedInUser") else {
            return
        }
        guard let storedUser = try? decoder.decode(LoggedInUser.self, from: storedUserData) else {
            return
        }
        self.appState.loggedInUser = storedUser
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onAppear(perform: handleInit)
        }
    }
}
