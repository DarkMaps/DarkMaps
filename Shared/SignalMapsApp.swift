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
    @Environment(\.scenePhase) private var scenePhase
    
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
        }.onChange(of: scenePhase) { phase in
            if phase == .active {
                if let loggedInUser = self.appState.loggedInUser {
                    if let subscriptionExpiryDate = loggedInUser.subscriptionExpiryDate {
                        if subscriptionExpiryDate.timeIntervalSince1970 < Date().timeIntervalSince1970 {
                            let subscriptionController = SubscriptionController()
                            subscriptionController.verifyIsStillSubscriber() { verifyResult in
                                switch verifyResult {
                                case .success(let isSubscriber):
                                    if !isSubscriber {
                                        print("User is no longer subscribed")
                                        self.appState.loggedInUser?.subscriptionExpiryDate = nil
                                    }
                                default:
                                    print("Failed to verify subscription status")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
