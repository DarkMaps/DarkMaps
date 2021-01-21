//
//  SignalMapsApp.swift
//  Shared
//
//  Created by Matthew Roche on 28/11/2020.
//

// https://peterfriese.dev/ultimate-guide-to-swiftui2-application-lifecycle/

import SwiftUI

@main
class SignalMapsApp: App {
    
    @StateObject private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase
    @State var serverOutOfSyncSheetIsShowing = false
    
    private let notificationCentre = NotificationCenter.default
    
    required init() {
        notificationCentre.addObserver(self,
                                       selector: #selector(self.handleServerOutOfSync(_:)),
                                       name: .encryptionController_ServerOutOfSync,
                                       object: nil)
    }
    
    @objc private func handleServerOutOfSync(_ notification: NSNotification) {
        serverOutOfSyncSheetIsShowing = true
    }
    
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
                    subscriptionController.verifyIsStillSubscriber() { [weak self] verifyResult in
                        guard let self = self else {return}
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
    
    // Required by storekit
    func handleCompleteTransactions() {
        let subscriptionController = SubscriptionController()
        subscriptionController.handleCompleteTransactions() { [weak self] completeTransactionsOutcome in
            guard let self = self else {
                return
            }
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
            ZStack {
                ContentView()
                    .environmentObject(appState)
                    .onAppear(perform: handleLoadStoredUser)
                    .onAppear(perform: handleCompleteTransactions)
                Text("").hidden().sheet(isPresented: $serverOutOfSyncSheetIsShowing) {
                    ServerDeviceChangedSheet().allowAutoDismiss(false)
                }
            }
        }.onChange(of: scenePhase) { [weak self] phase in
            guard let self = self else {
                return
            }
            if phase == .active {
                self.handleCheckUserIsSubscriber()
            }
        }
    }
}
