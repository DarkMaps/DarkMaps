//
//  LoginController.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 06/12/2020.
//

import SwiftUI

struct LoginController: View {
    
    @EnvironmentObject var appState: AppState
    
    @Binding var customAuthServer: String
    
    @State private var customServerModalVisible = false
    @State private var loginInProgress = false
    @State private var password = ""
    @State private var username = ""
    @State private var ephemeralCode: String? = nil
    @State private var twoFactorCode = ""
    @State private var twoFactorModalVisible = false
    @State private var showingDeleteDeviceSheet = false
    @State private var storedNewUser: LoggedInUser? = nil
    @State private var resetPasswordAlertShowing = false
    @State private var resetPasswordRequestedEmail = ""
    @State private var resetPasswordSuccessAlertShowing = false
    @State private var loginBoxShowing = true
    
    var authorisationController = AuthorisationController()
    
    private func handleCreateDevice(newUser: LoggedInUser) -> Void {
        
        guard let messagingController = try? MessagingController(userName: newUser.userName, serverAddress: newUser.serverAddress, authToken: newUser.authCode) else {
            appState.displayedError = IdentifiableError(MessagingControllerError.unableToCreateAddress)
            return
        }
        
        loginInProgress = true
            
        messagingController.createDevice(
            userName: newUser.userName,
            serverAddress: newUser.serverAddress,
            authToken: newUser.authCode) {
            createDeviceOutcome in
            
            loginInProgress = false
            
            switch createDeviceOutcome {
            case .failure(let error):
                if error == .remoteDeviceExists {
                    self.showingDeleteDeviceSheet = true
                } else {
                    appState.displayedError = IdentifiableError(error)
                }
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
            serverAddress: customAuthServer
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
        
        guard let storedNewUser = self.storedNewUser else {
            appState.displayedError = IdentifiableError(MessagingControllerError.unableToDeleteDevice)
            return
        }
        
        guard let messagingController = try? MessagingController(userName: storedNewUser.userName) else {
            appState.displayedError = IdentifiableError(MessagingControllerError.unableToCreateAddress)
            return
        }
        
        loginInProgress = true
        
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
            serverAddress: customAuthServer) { outcome in
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
    
    func resetPassword() {
        authorisationController.resetPassword(username: resetPasswordRequestedEmail, serverAddress: customAuthServer) { resetOutcome in
            
            switch resetOutcome {
            case .success:
                resetPasswordSuccessAlertShowing = true
            case .failure (let error):
                appState.displayedError = IdentifiableError(error)
            }
            
        }
        
    }
    
    var body: some View {
        ZStack {
            LoginView(
                username: $username,
                password: $password,
                customServerModalVisible: $customServerModalVisible,
                loginInProgress: $loginInProgress,
                resetPasswordAlertShowing: $resetPasswordAlertShowing,
                loginBoxShowing: $loginBoxShowing,
                performLogin: handleLogin
            )
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification), perform: {_ in
                withAnimation {
                    self.loginBoxShowing = false
                }
            })
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidHideNotification), perform: {_ in
                withAnimation {
                    self.loginBoxShowing = true
                }
            })
            Text("").hidden().actionSheet(isPresented: $showingDeleteDeviceSheet) {
                ActionSheet(
                    title: Text("Device already exists"),
                    message: Text("This account already has a registered device. Do you wish to delete it? This is irreversible."),
                    buttons: [
                        .cancel(),
                        .destructive(Text("Delete device from server"), action: handleDeleteDeviceThenLogin)
                    ]
                )
            }
            Text("").hidden().textFieldAlert(
                isShowing: $resetPasswordAlertShowing,
                text: $resetPasswordRequestedEmail,
                title: "Enter the email address of the user you would like to reset the password for.",
                textBoxPlaceholder: "Email",
                secureField: false,
                onDismiss: resetPassword
            )
            Text("").hidden().alert(isPresented: $resetPasswordSuccessAlertShowing) {
                Alert(
                    title: Text("Success"),
                    message: Text("If \(resetPasswordRequestedEmail) is registered on our server then a reset password email will have been sent to them."),
                    dismissButton: .default(Text("OK"))
                )
            }
            Text("").hidden().sheet(
                isPresented: $twoFactorModalVisible) {
                    TwoFactorModal(
                        twoFactorCode: $twoFactorCode,
                        loginInProgress: $loginInProgress,
                        submitTwoFactor: submitTwoFactor
                    )
            }
            Text("").hidden().sheet(
                isPresented: $customServerModalVisible) {
                    CustomServerModal(serverAddress: $customAuthServer)
            }
                
        }
        
    }
}

