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
                TabView(selection: $homeTabSelection) {
                    ListController().tabItem {
                        Text("List").font(.largeTitle)
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
                }
                .accentColor(Color("AccentColor"))
                .onAppear(perform: {
                    UITabBar.appearance().barTintColor = .blue
                    self.homeTabSelection = 1
                })
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
