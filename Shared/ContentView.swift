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
    @State var customAuthServer = "https://api.dark-maps.com"
    @State var authTabSelection: Int = 1
    @State var homeTabSelection: Int = 1
    
    var body: some View {
        ZStack {
            if $appState.loggedInUser.wrappedValue != nil {
                TabView(selection: $homeTabSelection) {
                    ListController().tabItem {
                        Text("List")
                        Image(systemName: "list.dash")
                    }.tag(1)
                    NewChatController().tabItem {
                        Text("New Chat")
                        Image(systemName: "plus")
                    }.tag(2)
                    SettingsController().tabItem {
                        Text("Settings")
                        Image(systemName: "gear")
                    }.tag(3)
                }.onAppear(perform: {
                    self.homeTabSelection = 1
                })
            } else {
                TabView(selection: $authTabSelection) {
                    LoginController(customAuthServer: $customAuthServer).tabItem {
                        Text("Login")
                        Image(systemName: "key.fill")
                    }.tag(1)
                    RegisterController(customAuthServer: $customAuthServer).tabItem {
                        Text("Register")
                        Image(systemName: "person.fill.badge.plus")
                    }.tag(2)
                }.onAppear(perform: {
                    self.authTabSelection = 1
                })
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
