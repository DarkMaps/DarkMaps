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
                    appState.displayedError = IdentifiableError(error)
                }
            }
        }
    }
    
    func submitTwoFactor(_ twoFactorCode: String) {
        loginInProgress = true
        authorisationController.submitTwoFactor(
            username: username,
            code: twoFactorCode,
            ephemeralToken: ephemeralCode ?? "unknown",
            serverAddress: serverAddress) { outcome in
            DispatchQueue.main.async {
                loginInProgress = false
                switch outcome {
                case .success(let newUser):
                    appState.loggedInUser = newUser
                case .failure(let error):
                    appState.displayedError = IdentifiableError(error)
                }
            }
        }
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

