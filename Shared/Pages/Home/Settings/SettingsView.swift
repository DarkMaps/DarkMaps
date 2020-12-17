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
    @Binding var loggedInUser: LoggedInUser?
    
    var logUserOut: () -> Void
    var deleteUserAccount: () -> Void
    
    var body: some View {
        List {
            Section(header: Text("User")) {
                Text("Username: \(loggedInUser?.userName ?? "Unknown")")
                Text("Device ID: \(loggedInUser?.deviceName ?? "Unknown")")
                Text("Server Address: \(loggedInUser?.serverAddress ?? "Unknown")")
            }
            Section(header: Text("Account")) {
                if (loggedInUser?.is2FAUser ?? false) {
                    Text("Deactivate 2FA").onTapGesture(perform: {
                        print("Click")
                        deactivate2FAModalIsShowing = true
                    })
                } else {
                    Text("Activate 2FA").onTapGesture(perform: {
                        print("Click")
                        activate2FAModalIsShowing = true
                    })
                }
                Text("Log Out")
                    .onTapGesture(perform: logUserOut)
                Text("Delete Account")
                    .onTapGesture(perform: deleteUserAccount)
            }
        }.listStyle(GroupedListStyle())
    }
}

struct SettingsView_Previews: PreviewProvider {
    
    static var previews: some View {
        return Group {
            PreviewWrapper(is2FAUser: true)
                .previewDisplayName("2FA")
            PreviewWrapper(is2FAUser: false)
                .previewDisplayName("No 2FA")
        }
    }
    
    struct PreviewWrapper: View {
        
        func logUserOut() {}
        func deleteUserAccount() {}
        
        @State var loggedInUser: LoggedInUser? = nil
        @State var is2FAUser: Bool
        @State var activate2FAModalIsShowing = false
        @State var deactivate2FAModalIsShowing = false

        var body: some View {
            
            return SettingsView(
                activate2FAModalIsShowing: $activate2FAModalIsShowing,
                deactivate2FAModalIsShowing: $deactivate2FAModalIsShowing,
                loggedInUser: $loggedInUser,
                logUserOut: logUserOut,
                deleteUserAccount: deleteUserAccount
            )
        }
    }
    
}
