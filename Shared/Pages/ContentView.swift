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
    @State var homeTabSelection: Int = 1
    
    var body: some View {
        ZStack {
            if $appState.loggedInUser.wrappedValue != nil {
                TabHolder()
            } else {
                Entry()
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
