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
    
    func handleRegister() -> Void {
        withAnimation {
            registerInProgress = true
        }
        authorisationController.register(
            username: username,
            password: password,
            serverAddress: customAuthServer
        ) { registerOutcome in
            
            switch registerOutcome {
            case .failure(let error):
                withAnimation {
                    registerInProgress = false
                }
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
                        withAnimation {
                            registerInProgress = false
                        }
                        appState.displayedError = IdentifiableError(SSAPIAuthRegisterError.loginError)
                    }
                }
            }
        }
    }
    
    private func handleCreateDevice(newUser: LoggedInUser) -> Void {
        
        guard let messagingController = try? MessagingController(userName: newUser.userName, serverAddress: newUser.serverAddress, authToken: newUser.authCode) else {
            appState.displayedError = IdentifiableError(MessagingControllerError.unableToCreateAddress)
            registerInProgress = false
            return
        }
        
        withAnimation {
            registerInProgress = true
        }
            
        messagingController.createDevice(
            userName: newUser.userName,
            serverAddress: newUser.serverAddress,
            authToken: newUser.authCode) {
            createDeviceOutcome in
            
            switch createDeviceOutcome {
            case .failure(let error):
                withAnimation {
                    registerInProgress = false
                }
                appState.displayedError = IdentifiableError(error)
            case .success(let _):
                appState.messagingController = messagingController
                handleCheckSubscriptionStatus(newUser: newUser)
            }
        }
    }
    
    func handleCheckSubscriptionStatus(newUser: LoggedInUser) -> Void {
        
        withAnimation {
            registerInProgress = true
        }
        
        let subscriptionController = appState.subscriptionController
        
        subscriptionController.verifyReceipt() { verifyResult in
            
            withAnimation {
                registerInProgress = false
            }
            
            switch verifyResult {
            case.failure(let error):
                print(error)
                DispatchQueue.main.async {
                    if error == .expiredPurchase {
                        appState.displayedError = IdentifiableError(error)
                    }
                    withAnimation {
                        appState.loggedInUser = newUser
                    }
                }
            case .success(let expiryDate):
                print(expiryDate)
                DispatchQueue.main.async {
                    withAnimation {
                        appState.loggedInUser = newUser
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

