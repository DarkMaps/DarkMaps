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
    
    func handleLoadStoredUser() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let storedUserData = KeychainSwift().getData("loggedInUser") else {
            return
        }
        guard let storedUser = try? decoder.decode(LoggedInUser.self, from: storedUserData) else {
            return
        }
        guard let messagingController = try? MessagingController(userName: storedUser.userName, serverAddress: storedUser.serverAddress, authToken: storedUser.authCode) else {
            return
        }
        self.appState.loggedInUser = storedUser
        self.appState.messagingController = messagingController
    }
    
    func handleCheckUserIsSubscriber() {
        print("Handle check user is subscriber")
        if let loggedInUser = self.appState.loggedInUser {
            if let subscriptionExpiryDate = loggedInUser.subscriptionExpiryDate {
                if subscriptionExpiryDate.timeIntervalSince1970 < Date().timeIntervalSince1970 {
                    let subscriptionController = SubscriptionController()
                    subscriptionController.verifyIsStillSubscriber() { verifyResult in
                        switch verifyResult {
                        case .success(let expirationDate):
                            print("User is still subscribed")
                            self.appState.loggedInUser?.subscriptionExpiryDate = expirationDate
                        default:
                            print("Failed to verify subscription status")
                            self.appState.loggedInUser?.subscriptionExpiryDate = nil
                        }
                    }
                }
            }
        }
    }
    
    func handleCompleteTransactions() {
        let subscriptionController = SubscriptionController()
        subscriptionController.handleCompleteTransactions() { completeTransactionsOutcome in
            switch completeTransactionsOutcome {
            case .success(let expiryDate):
                if let _ = self.appState.loggedInUser {
                    self.appState.loggedInUser?.subscriptionExpiryDate = expiryDate
                }
            default:
                return
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onAppear(perform: handleLoadStoredUser)
                .onAppear(perform: handleCompleteTransactions)
        }.onChange(of: scenePhase) { phase in
            if phase == .active {
                handleCheckUserIsSubscriber()
            }
        }
    }
}
