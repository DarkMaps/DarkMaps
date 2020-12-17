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
    @State private var ephemeralCode: String? = nil
    @State private var twoFactorCode = ""
    @State private var twoFactorModalVisible = false
    
    var authorisationController = AuthorisationController()
    
    func handleLogin() -> Void {
        loginInProgress = true
        authorisationController.login(
            username: username,
            password: password,
            serverAddress: serverAddress
        ) { loginOutcome in
            DispatchQueue.main.async {
                loginInProgress = false
                switch loginOutcome {
                case .success(let newUser):
                    appState.loggedInUser = newUser
                case .twoFactorRequired(let ephemeralCodeReceived):
                    ephemeralCode = ephemeralCodeReceived
                    twoFactorModalVisible = true
                case .failure(let error):
                    print(error)
                    print(error.localizedDescription)
                    appState.displayedError = IdentifiableError(error)
                }
            }
        }
    }
    
    func submitTwoFactor(_ twoFactorCode: String) {
        loginInProgress = true
        authorisationController.submitTwoFactor(
            ephemeralCode: "a",
            twoFactorCode: twoFactorCode,
            username: username,
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
            twoFactorModalVisible: $twoFactorModalVisible,
            loginInProgress: $loginInProgress,
            serverAddress: $serverAddress,
            twoFactorCode: $twoFactorCode,
            performLogin: handleLogin,
            submitTwoFactor: submitTwoFactor
        )
    }
}

