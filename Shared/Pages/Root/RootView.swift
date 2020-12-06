//
//  RootView.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 05/12/2020.
//

import SwiftUI
import CoreLocation

struct RootView: View {

    @EnvironmentObject var appState: AppState
    
    var body: some View {
        if appState.loggedInUser == nil {
            return NavigationView{AnyView(
                ZStack {
                    LoginController()
                }
            )}
        } else {
            return NavigationView{AnyView(
                ZStack {
                    Text("Logged In")
                }
            )}
        }
    }
}
