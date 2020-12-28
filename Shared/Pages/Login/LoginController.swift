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
    @State private var showingDeleteDeviceSheet = false
    @State private var storedNewUser: LoggedInUser? = nil
    
    var authorisationController = AuthorisationController()
    var messagingController = MessagingController()
    
    func handleLogin() -> Void {
        loginInProgress = true
        authorisationController.login(
            username: username,
            password: password,
            serverAddress: serverAddress
        ) { loginOutcome in
            
            switch loginOutcome {
            case .twoFactorRequired(let ephemeralCodeReceived):
                ephemeralCode = ephemeralCodeReceived
                twoFactorModalVisible = true
            case .failure(let error):
                appState.displayedError = IdentifiableError(error)
            case .success(let newUser):
                
                storedNewUser = newUser
                    
                messagingController.createDevice(
                    userName: newUser.userName,
                    serverAddress: newUser.serverAddress,
                    authToken: newUser.authCode) {
                    createDeviceOutcome in
                    
                    loginInProgress = false
                    
                    switch createDeviceOutcome {
                    case .failure(let error):
                        appState.displayedError = IdentifiableError(error)
                    case .success(let registrationId):
                        print("Registration Id: \(registrationId)")
                        appState.loggedInUser = newUser
                    }
                }
            }
        }
    }
    
    func handleDeleteDeviceThenLogin() -> Void {
        
        loginInProgress = true
        
        guard let storedNewUser = self.storedNewUser else {
            appState.displayedError = IdentifiableError(MessagingControllerError.unableToDeleteDevice)
            return
        }
        
        messagingController.deleteDevice(
            userName: storedNewUser.userName,
            serverAddress: storedNewUser.serverAddress,
            authToken: storedNewUser.authCode) {
            deleteDeviceOutcome in
            switch deleteDeviceOutcome {
            case .failure(let error):
                appState.displayedError = IdentifiableError(error)
            case .success():
                
                messagingController.createDevice(
                    userName: storedNewUser.userName,
                    serverAddress: storedNewUser.serverAddress,
                    authToken: storedNewUser.authCode) {
                    createDeviceOutcome in
                    
                    loginInProgress = false
                    
                    switch createDeviceOutcome {
                    case .failure(let error):
                        appState.displayedError = IdentifiableError(error)
                    case .success(let registrationId):
                        print("Registration Id: \(registrationId)")
                        appState.loggedInUser = storedNewUser
                    }
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
                twoFactorModalVisible = false
                switch outcome {
                case .success(let newUser):
                    appState.loggedInUser = newUser
                case .failure(let error):
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                        appState.displayedError = IdentifiableError(error)
                    })
                }
            }
        }
    }
    
    var body: some View {
        ZStack {
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
            Text("").hidden().actionSheet(isPresented: $showingDeleteDeviceSheet) {
                ActionSheet(
                    title: Text("Device already exists"),
                    message: Text("This account already has a registered device. Do you wish to delete it? This is irreversible."),
                    buttons: [
                        .cancel(),
                        .destructive(Text("Delete device from server."), action: handleDeleteDeviceThenLogin)
                    ]
                )
            }
        }
        
    }
}

