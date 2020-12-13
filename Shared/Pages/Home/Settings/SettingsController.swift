//
//  SettingsController.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 08/12/2020.
//
import SwiftUI

struct SettingsController: View {
    
    @EnvironmentObject var appState: AppState
    
    var authorisationController = AuthorisationController()
    
    func logUserOut() {
        authorisationController.logUserOut(appState: appState)
    }
    
    var body: some View {
        ZStack {
            SettingsView(
                logUserOut: logUserOut
            )
        }
        
    }
}
