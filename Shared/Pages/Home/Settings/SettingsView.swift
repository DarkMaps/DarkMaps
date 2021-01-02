//
//  SettingsView.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 08/12/2020.
//

import SwiftUI

struct SettingsView: View {
    
    @Binding var activate2FAModalIsShowing: Bool
    @Binding var deactivate2FAModalIsShowing: Bool
    @Binding var passwordAlertShowing: Bool
    @Binding var loggedInUser: LoggedInUser?
    @Binding var actionInProgress: ActionInProgress?
    
    var logUserOut: () -> Void
    var getSubscriptionOptions: () -> Void
    var restoreSubscription: () -> Void
    var dateFormatter = DateFormatter()
    
    func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yyyy"
        return dateFormatter.string(from: date)
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("User")) {
                    Text("Username: \(loggedInUser?.userName ?? "Unknown")")
                    Text("Device ID: \(String(loggedInUser?.deviceId ?? -1))")
                    Text("Server Address: \(loggedInUser?.serverAddress ?? "Unknown")")
                }
                Section(header: Text("Account")) {
                    if (loggedInUser?.is2FAUser ?? false) {
                        SettingsRow(
                            actionInProgress: $actionInProgress,
                            title: "Deactivate 2FA",
                            actionDefiningActivityMarker: .deactivate2FA,
                            onTap: {deactivate2FAModalIsShowing = true}
                        )
                    } else {
                        SettingsRow(
                            actionInProgress: $actionInProgress,
                            title: "Activate 2FA",
                            actionDefiningActivityMarker: .confirm2FA,
                            onTap: {activate2FAModalIsShowing = true}
                        )
                    }
                    SettingsRow(
                        actionInProgress: $actionInProgress,
                        title: "Log Out",
                        actionDefiningActivityMarker: .logUserOut,
                        onTap: logUserOut
                    )
                    SettingsRow(
                        actionInProgress: $actionInProgress,
                        title: "Delete Account",
                        actionDefiningActivityMarker: .deleteUserAccount,
                        onTap: {passwordAlertShowing = true}
                    )
                }
                Section(header: Text("Subscription")) {
                    if loggedInUser?.subscriptionExpiryDate == nil {
                        SettingsRow(
                            actionInProgress: $actionInProgress,
                            title: "Subscribe",
                            actionDefiningActivityMarker: .subscribe,
                            onTap: getSubscriptionOptions
                        )
                        SettingsRow(
                            actionInProgress: $actionInProgress,
                            title: "Restore Subscription",
                            actionDefiningActivityMarker: .restoreSubscription,
                            onTap: restoreSubscription
                        )
                    } else {
                        Text("You are subscribed until: \(formatDate(loggedInUser!.subscriptionExpiryDate!))")
                    }

                }
            }
            .listStyle(GroupedListStyle())
            .navigationTitle("Settings")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    
    static var previews: some View {
        return Group {
            PreviewWrapper()
            PreviewWrapper(loggedInUser: LoggedInUser(
                userName: "testUser@test.com",
                deviceId: 1,
                serverAddress: "https://api.test.com",
                authCode: "testAuthCode",
                is2FAUser: false,
                subscriptionExpiryDate: Date()))
            PreviewWrapper(loggedInUser: LoggedInUser(
                            userName: "testUser@test.com",
                            deviceId: 1,
                            serverAddress: "https://api.test.com",
                            authCode: "testAuthCode",
                            is2FAUser: true))
        }
    }
    
    struct PreviewWrapper: View {
        
        func logUserOut() {}
        func getSubscriptionOptions() {}
        func restoreSubscription() {}
        
        @State var loggedInUser: LoggedInUser?
        @State var activate2FAModalIsShowing = false
        @State var deactivate2FAModalIsShowing = false
        @State var passwordAlertShowing = false
        @State var actionInProgress: ActionInProgress? = nil
        
        init(loggedInUser: LoggedInUser? = nil) {
            _loggedInUser = State(initialValue: loggedInUser)
        }

        var body: some View {
            
            return SettingsView(
                activate2FAModalIsShowing: $activate2FAModalIsShowing,
                deactivate2FAModalIsShowing: $deactivate2FAModalIsShowing,
                passwordAlertShowing: $passwordAlertShowing,
                loggedInUser: $loggedInUser,
                actionInProgress: $actionInProgress,
                logUserOut: logUserOut,
                getSubscriptionOptions: getSubscriptionOptions,
                restoreSubscription: restoreSubscription
            )
        }
    }
    
}
