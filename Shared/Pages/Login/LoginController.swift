//
//  LoginController.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 06/12/2020.
//

import SwiftUI

struct LoginController: View {
    
    @EnvironmentObject var appState: AppState
    
    @State private var customServerModalVisible = false
    @State private var loginInProgress = false
    @State private var password = ""
    @State private var username = ""
    @State private var serverAddress = "https://www.simplesignal.co.uk"
    
    var authorisationController = AuthorisationController()
    
    func handleLogin() -> Void {
        loginInProgress = true
        authorisationController.login(
            username: username,
            password: password,
            serverAddress: serverAddress,
            appState: appState
        )
        loginInProgress = false
    }
    
    var body: some View {
        LoginView(
            username: $username,
            password: $password,
            customServerModalVisible: $customServerModalVisible,
            loginInProgress: $loginInProgress,
            serverAddress: $serverAddress,
            performLogin: handleLogin
        )
    }
}

