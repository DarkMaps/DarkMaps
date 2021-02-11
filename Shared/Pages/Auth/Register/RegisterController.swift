//
//  RegisterController.swift
//  DarkMaps (iOS)
//
//  Created by Matthew Roche on 05/01/2021.
//

import SwiftUI

struct RegisterController: View {
    
    @EnvironmentObject var appState: AppState
    
    @Binding var customAuthServer: String
    
    @State private var customServerModalVisible = false
    @State private var registerInProgress = false
    @State private var password = ""
    @State private var username = ""
    @State private var storedNewUser: LoggedInUser? = nil
    
    var authorisationController = AuthorisationController()
    
    private func handleCreateDevice(newUser: LoggedInUser) -> Void {
        
        guard let messagingController = try? MessagingController(userName: newUser.userName, serverAddress: newUser.serverAddress, authToken: newUser.authCode) else {
            appState.displayedError = IdentifiableError(MessagingControllerError.unableToCreateAddress)
            registerInProgress = false
            return
        }
        
        registerInProgress = true
            
        messagingController.createDevice(
            userName: newUser.userName,
            serverAddress: newUser.serverAddress,
            authToken: newUser.authCode) {
            createDeviceOutcome in
            
            switch createDeviceOutcome {
            case .failure(let error):
                registerInProgress = false
                appState.displayedError = IdentifiableError(error)
            case .success(let registrationId):
                print("Registration Id: \(registrationId)")
                appState.messagingController = messagingController
                handleCheckSubscriptionStatus(newUser: newUser)
            }
        }
    }
    
    func handleCheckSubscriptionStatus(newUser: LoggedInUser) -> Void {
        
        registerInProgress = true
        
        let subscriptionController = appState.subscriptionController
        
        subscriptionController.verifyReceipt() { verifyResult in
            
            registerInProgress = false
            
            switch verifyResult {
            case.failure(let error):
                print(error)
                DispatchQueue.main.async {
                    if error == .expiredPurchase {
                        appState.displayedError = IdentifiableError(error)
                    }
                    appState.loggedInUser = newUser
                }
            case .success(let expiryDate):
                print(expiryDate)
                DispatchQueue.main.async {
                    appState.loggedInUser = newUser
                }
            }
        }
        
    }
    
    func handleRegister() -> Void {
        registerInProgress = true
        authorisationController.register(
            username: username,
            password: password,
            serverAddress: customAuthServer
        ) { registerOutcome in
            
            switch registerOutcome {
            case .failure(let error):
                appState.displayedError = IdentifiableError(error)
            case .success:
                
                authorisationController.login(
                    username: username,
                    password: password,
                    serverAddress: customAuthServer
                ) { loginOutcome in
                    
                    switch loginOutcome {
                    case .success(let newUser):
                        storedNewUser = newUser
                        handleCreateDevice(newUser: newUser)
                    default:
                        registerInProgress = false
                        appState.displayedError = IdentifiableError(SSAPIAuthRegisterError.loginError)
                    }
                }
            }
        }
    }
    
    var body: some View {
        ZStack {
            RegisterView(
                username: $username,
                password: $password,
                registerInProgress: $registerInProgress,
                customServerModalVisible: $customServerModalVisible,
                performRegister: handleRegister
            )
            Text("").hidden().sheet(isPresented: $customServerModalVisible) {
                CustomServerModal(serverAddress: $customAuthServer)
            }
        }
        
    }
}

