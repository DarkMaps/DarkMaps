//
//  HomeView.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 06/12/2020.
//

import SwiftUI

enum HomeViewState {
    case list, newChat, settings
}

struct HomeView: View {
    
    @EnvironmentObject var appState: AppState
    
    @State var homeViewState = HomeViewState.list
    
    var body: some View {
        VStack {
            Group {
                if homeViewState == .list {
                    ListController()
                } else if homeViewState == .newChat {
                    NewChatController()
                } else if homeViewState == .settings {
                    SettingsController()
                }
            }
            Spacer()
            HStack {
                Spacer()
                HomeViewButton(
                    title: "List",
                    imageName: "list.dash",
                    onTap: {homeViewState = .list})
                Spacer()
                HomeViewButton(
                    title: "New Chat",
                    imageName: "plus",
                    onTap: {homeViewState = .newChat})
                Spacer()
                HomeViewButton(
                    title: "Settings",
                    imageName: "gear",
                    onTap: {homeViewState = .settings})
                Spacer()
            }
            .frame(height: 48)
            .padding(.top, 6)
            .overlay(
                Rectangle()
                    .frame(
                        width: nil,
                        height: 1,
                        alignment: .top)
                    .foregroundColor(Color.gray),
                alignment: .top
            )
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    
    static var previews: some View {
        PreviewWrapper()
    }
    
    struct PreviewWrapper: View {
        var appState = AppState()
        var body: some View {
            return HomeView().environmentObject(appState)
        }
    }
    
}
