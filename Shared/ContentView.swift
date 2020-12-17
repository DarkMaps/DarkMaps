//
//  ContentView.swift
//  Shared
//
//  Created by Matthew Roche on 28/11/2020.
//

import SwiftUI
import SignalFfi

struct ContentView: View {
    
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            if $appState.loggedInUser.wrappedValue != nil {
                HomeView()
            } else {
                LoginController()
            }
            Text("").hidden().alert(item: $appState.displayedError) { viewError -> Alert in
                ErrorAlert(viewError: viewError)
            }
        }
    }
}
