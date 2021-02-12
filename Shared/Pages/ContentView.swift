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
    @Binding var loadComplete: Bool
    @State var homeTabSelection: Int = 1
    
    var body: some View {
        ZStack {
            if loadComplete == false {
                Splash()
                    .transition(.opacity)
            } else if $appState.loggedInUser.wrappedValue != nil {
                TabHolder()
                    .transition(.opacity)
            } else {
                Entry()
                    .transition(.opacity)
            }
            Text("").hidden().alert(item: $appState.displayedError) { viewError -> Alert in
                ErrorAlert(viewError: viewError)
            }
            Text("").hidden().sheet(isPresented: $appState.subscriptionSheetIsShowing) {
                SubscriptionSheet()
            }
        }
    }
}
