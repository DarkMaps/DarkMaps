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
    
    var body: some View {
        List {
            Section(header: Text("User")) {
                Text("Username: \(loggedInUser?.userName ?? "Unknown")")
                Text("Device ID: \(loggedInUser?.deviceName ?? "Unknown")")
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
        }.listStyle(GroupedListStyle())
    }
}

struct SettingsView_Previews: PreviewProvider {
    
    static var previews: some View {
        return Group {
            PreviewWrapper()
        }
    }
    
    struct PreviewWrapper: View {
        
        func logUserOut() {}
        
        @State var loggedInUser: LoggedInUser? = nil
        @State var activate2FAModalIsShowing = false
        @State var deactivate2FAModalIsShowing = false
        @State var passwordAlertShowing = false
        @State var actionInProgress: ActionInProgress? = nil

        var body: some View {
            
            return SettingsView(
                activate2FAModalIsShowing: $activate2FAModalIsShowing,
                deactivate2FAModalIsShowing: $deactivate2FAModalIsShowing,
                passwordAlertShowing: $passwordAlertShowing,
                loggedInUser: $loggedInUser,
                actionInProgress: $actionInProgress,
                logUserOut: logUserOut
            )
        }
    }
    
}
