//
//  SettingsView.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 08/12/2020.
//

import SwiftUI

struct SettingsView: View {
    
    @EnvironmentObject var appState: AppState
    
    @Binding var activate2FAModalIsShowing: Bool
    @Binding var deactivate2FAModalIsShowing: Bool
    @Binding var passwordAlertShowing: Bool
    @Binding var loggedInUser: LoggedInUser?
    @Binding var actionInProgress: ActionInProgress?
    
    var logUserOut: () -> Void
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
                    SettingsRow(
                        actionInProgress: $actionInProgress,
                        title: "Username: \(loggedInUser?.userName ?? "Unknown")",
                        iconName: "person.fill",
                        actionDefiningActivityMarker: nil,
                        isTappable: false)
                    SettingsRow(
                        actionInProgress: $actionInProgress,
                        title: "Device ID: \(String(loggedInUser?.deviceId ?? -1))",
                        iconName: "number",
                        actionDefiningActivityMarker: nil,
                        isTappable: false)
                    SettingsRow(
                        actionInProgress: $actionInProgress,
                        title: "Server Address",
                        subtitle: "\(loggedInUser?.serverAddress ?? "Unknown")",
                        iconName: "curlybraces",
                        actionDefiningActivityMarker: nil,
                        isTappable: false)
                }
                Section(header: Text("App")) {
                    SettingsRow(
                        actionInProgress: $actionInProgress,
                        title: "Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")",
                        iconName: "number",
                        actionDefiningActivityMarker: nil,
                        isTappable: false)
                    SettingsRow(
                        actionInProgress: $actionInProgress,
                        title: "Build: \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")",
                        iconName: "number",
                        actionDefiningActivityMarker: nil,
                        isTappable: false)
                }
                Section(header: Text("Account")) {
                    if (loggedInUser?.is2FAUser ?? false) {
                        SettingsRow(
                            actionInProgress: $actionInProgress,
                            title: "Deactivate 2FA",
                            iconName: "minus.diamond.fill",
                            actionDefiningActivityMarker: .deactivate2FA,
                            onTap: {deactivate2FAModalIsShowing = true}
                        )
                    } else {
                        SettingsRow(
                            actionInProgress: $actionInProgress,
                            title: "Activate 2FA",
                            iconName: "plus.diamond.fill",
                            actionDefiningActivityMarker: .confirm2FA,
                            onTap: {activate2FAModalIsShowing = true}
                        )
                    }
                    SettingsRow(
                        actionInProgress: $actionInProgress,
                        title: "Log Out",
                        iconName: "person.fill.badge.minus",
                        actionDefiningActivityMarker: .logUserOut,
                        onTap: logUserOut
                    )
                    SettingsRow(
                        actionInProgress: $actionInProgress,
                        title: "Delete Account",
                        iconName: "figure.wave",
                        actionDefiningActivityMarker: .deleteUserAccount,
                        onTap: {passwordAlertShowing = true}
                    )
                }
                Section(header: Text("Subscription")) {
                    if loggedInUser?.subscriptionExpiryDate == nil {
                        SettingsRow(
                            actionInProgress: $actionInProgress,
                            title: "Subscribe",
                            iconName: "creditcard.fill",
                            actionDefiningActivityMarker: .subscribe,
                            onTap: {
                                appState.subscriptionSheetIsShowing = true
                            }
                        )
                        SettingsRow(
                            actionInProgress: $actionInProgress,
                            title: "Restore Subscription",
                            iconName: "arrow.clockwise",
                            actionDefiningActivityMarker: .restoreSubscription,
                            onTap: restoreSubscription
                        )
                    } else {
                        Text("You are subscribed until: \(formatDate(loggedInUser!.subscriptionExpiryDate!))")
                        SettingsRow(
                            actionInProgress: $actionInProgress,
                            title: "Manage Subscriptions",
                            iconName: "gear",
                            actionDefiningActivityMarker: .subscriptionSettings,
                            onTap: {
                                if let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") {
                                    if UIApplication.shared.canOpenURL(url) {
                                        UIApplication.shared.open(url, options: [:])
                                    }
                                }
                            }
                        )
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
                            userName: "reallyreallyLongTestUser@test.com",
                            deviceId: 1,
                            serverAddress: "https://api.reallyreallylongtesturl.com",
                            authCode: "testAuthCode",
                            is2FAUser: true))
            PreviewWrapper(loggedInUser: LoggedInUser(
                            userName: "reallyreallyLongTestUser@test.com",
                            deviceId: 1,
                            serverAddress: "https://api.reallyreallylongtesturl.com",
                            authCode: "testAuthCode",
                            is2FAUser: true))
                .preferredColorScheme(.dark)
            PreviewWrapper(loggedInUser: LoggedInUser(
                            userName: "reallyreallyLongTestUser@test.com",
                            deviceId: 1,
                            serverAddress: "https://api.reallyreallylongtesturl.com",
                            authCode: "testAuthCode",
                            is2FAUser: true))
                .previewDevice("iPod touch (7th generation)")
                .preferredColorScheme(.dark)
        }
    }
    
    struct PreviewWrapper: View {
        
        func logUserOut() {}
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
                restoreSubscription: restoreSubscription
            )
        }
    }
    
}
