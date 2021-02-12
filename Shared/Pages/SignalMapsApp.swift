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
    @State var loadComplete = false
    @State var serverOutOfSyncSheetIsShowing = false
    @State var unauthorisedSheetIsShowing = false
    @State var subscriptionExpiredAlertShowing = false
    
    func handleLoadStoredUser() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let storedUserData = KeychainSwift().getData("loggedInUser") else {
            print("No stored data")
            return
        }
        do {
            let _ = try decoder.decode(LoggedInUser.self, from: storedUserData)
        } catch {
            print(error)
        }
        guard let storedUser = try? decoder.decode(LoggedInUser.self, from: storedUserData) else {
            print("Badly formatted data")
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
            print("Logged in")
            if let subscriptionExpiryDate = loggedInUser.subscriptionExpiryDate {
                print("Is subscribed - expires \(String(describing: loggedInUser.subscriptionExpiryDate?.debugDescription))")
                if subscriptionExpiryDate.timeIntervalSince1970 < Date().timeIntervalSince1970 {
                    print("Subscription has expired")
                    appState.subscriptionController.verifyReceipt() { verifyResult in
                        switch verifyResult {
                        case .success(let expirationDate):
                            print("User is still subscribed")
                            self.appState.loggedInUser?.subscriptionExpiryDate = expirationDate
                        case .failure(let error):
                            print("Failed to verify subscription status")
                            if error == .expiredPurchase {
                                self.subscriptionExpiredAlertShowing = true
                            } else {
                                appState.displayedError = IdentifiableError(error)
                            }
                            try? appState.handleNoLongerSubscribed()
                            
                        }
                    }
                }
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView(loadComplete: $loadComplete)
                    .environmentObject(appState)
                    .onAppear() {
                        self.appState.subscriptionController.startObserving()
                    }
                    .onDisappear() {
                        self.appState.subscriptionController.stopObserving()
                    }
                Text("").hidden().sheet(isPresented: $serverOutOfSyncSheetIsShowing) {
                    ServerDeviceChangedSheet().allowAutoDismiss(false).environmentObject(appState)
                }
                Text("").hidden().sheet(isPresented: $unauthorisedSheetIsShowing) {
                    UnauthorisedSheet().allowAutoDismiss(false).environmentObject(appState)
                }
                Text("").hidden().alert(isPresented: $subscriptionExpiredAlertShowing) {
                    Alert(
                        title: Text("Subscription Expired"),
                        message: Text("Your subscription has expired and you have now lost the ability to send live messages.\n\nPlease contact us at\n\nadmin@dark-maps.com\n\nif you believe you have been incorrectly charged."),
                        dismissButton: Alert.Button.default(Text("OK")))
                }
            }
            .accentColor(.accentColor)
            .onReceive(NotificationCenter.default.publisher(for: .encryptionController_ServerOutOfSync), perform: { _ in
                serverOutOfSyncSheetIsShowing = true
            })
            .onReceive(NotificationCenter.default.publisher(for: .communicationController_Unauthorised), perform: { _ in
                unauthorisedSheetIsShowing = true
            })
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                if appState.loggedInUser == nil {
                    self.handleLoadStoredUser()
                }
                DispatchQueue.main.async {
                    withAnimation {
                        loadComplete = true
                    }
                }
                // Don't wait for handleCheckUserIsSubscriber as this may involve an API call
                self.handleCheckUserIsSubscriber()
            }
        }
    }
}
