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
    @State private var serverAddress = "https://api.dark-maps.com"
    @State private var ephemeralCode: String? = nil
    @State private var twoFactorCode = ""
    @State private var twoFactorModalVisible = false
    @State private var showingDeleteDeviceSheet = false
    @State private var storedNewUser: LoggedInUser? = nil
    
    var authorisationController = AuthorisationController()
    
    private func handleCreateDevice(newUser: LoggedInUser) -> Void {
        
        loginInProgress = true
        
        guard let messagingController = try? MessagingController(userName: newUser.userName, serverAddress: newUser.serverAddress, authToken: newUser.authCode) else {
            appState.displayedError = IdentifiableError(MessagingControllerError.unableToCreateAddress)
            return
        }
            
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
                appState.messagingController = messagingController
                handleCheckSubscriptionStatus(newUser: newUser)
            }
        }
    }
    
    func handleCheckSubscriptionStatus(newUser: LoggedInUser) -> Void {
        
        loginInProgress = true
        
        let subscriptionController = SubscriptionController()
        
        subscriptionController.verifyIsStillSubscriber { verifyResult in
            
            loginInProgress = false
            
            switch verifyResult {
            case.failure(let error):
                print(error)
                appState.displayedError = IdentifiableError(error)
                appState.loggedInUser = newUser
            case .success(let expiryDate):
                print(expiryDate)
                appState.loggedInUser = newUser
            }
        }
        
    }
    
    func handleLogin() -> Void {
        loginInProgress = true
        authorisationController.login(
            username: username,
            password: password,
            serverAddress: serverAddress
        ) { loginOutcome in
            loginInProgress = false
            
            switch loginOutcome {
            case .twoFactorRequired(let ephemeralCodeReceived):
                ephemeralCode = ephemeralCodeReceived
                twoFactorModalVisible = true
            case .failure(let error):
                appState.displayedError = IdentifiableError(error)
            case .success(let newUser):
                storedNewUser = newUser
                handleCreateDevice(newUser: newUser)
            }
        }
    }
    
    func handleDeleteDeviceThenLogin() -> Void {
        
        loginInProgress = true
        
        guard let storedNewUser = self.storedNewUser else {
            appState.displayedError = IdentifiableError(MessagingControllerError.unableToDeleteDevice)
            return
        }
        
        guard let messagingController = try? MessagingController(userName: storedNewUser.userName) else {
            appState.displayedError = IdentifiableError(MessagingControllerError.unableToCreateAddress)
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
                
                handleCreateDevice(newUser: storedNewUser)
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
                    storedNewUser = newUser
                    handleCreateDevice(newUser: newUser)
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

