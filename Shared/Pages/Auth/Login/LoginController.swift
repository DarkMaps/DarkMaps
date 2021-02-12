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
    @State private var showingResetDeviceSheet = false
    @State private var storedNewUser: LoggedInUser? = nil
    @State private var resetPasswordAlertShowing = false
    @State private var resetPasswordRequestedEmail = ""
    @State private var resetPasswordSuccessAlertShowing = false
    
    var authorisationController = AuthorisationController()
    
    func handleLogin() -> Void {
        withAnimation {
            loginInProgress = true
        }
        authorisationController.login(
            username: username,
            password: password,
            serverAddress: customAuthServer
        ) { loginOutcome in
            
            switch loginOutcome {
            case .twoFactorRequired(let ephemeralCodeReceived):
                withAnimation {
                    loginInProgress = false
                }
                ephemeralCode = ephemeralCodeReceived
                twoFactorModalVisible = true
            case .failure(let error):
                withAnimation {
                    loginInProgress = false
                }
                appState.displayedError = IdentifiableError(error)
            case .success(let newUser):
                storedNewUser = newUser
                handleCreateDevice(newUser: newUser)
            }
        }
    }
    
    private func handleCreateDevice(newUser: LoggedInUser) -> Void {
        
        guard let messagingController = try? MessagingController(userName: newUser.userName, serverAddress: newUser.serverAddress, authToken: newUser.authCode) else {
            appState.displayedError = IdentifiableError(MessagingControllerError.unableToCreateAddress)
            withAnimation {
                loginInProgress = false
            }
            return
        }
        
        withAnimation {
            loginInProgress = true
        }
            
        messagingController.createDevice(
            userName: newUser.userName,
            serverAddress: newUser.serverAddress,
            authToken: newUser.authCode) {
            createDeviceOutcome in
            
            switch createDeviceOutcome {
            case .failure(let error):
                withAnimation {
                    loginInProgress = false
                }
                if error == .remoteDeviceExists {
                    self.showingDeleteDeviceSheet = true
                } else {
                    appState.displayedError = IdentifiableError(error)
                }
            case .success(let registrationId):
                appState.messagingController = messagingController
                handleSync(newUser: newUser)
            }
        }
    }
    
    private func handleSync(newUser: LoggedInUser) -> Void {
        // We need to sync to ensure that the local and remote devices match
        // If there is an existing local device and the user creates a new remote device
        // with another physical device they could become out of sync
        
        guard let messagingController = try? MessagingController(userName: newUser.userName, serverAddress: newUser.serverAddress, authToken: newUser.authCode) else {
            appState.displayedError = IdentifiableError(MessagingControllerError.unableToCreateAddress)
            loginInProgress = false
            return
        }
        
        withAnimation {
            loginInProgress = true
        }
        
        messagingController.getMessages(serverAddress: newUser.serverAddress, authToken: newUser.authCode) { getMessagesOutcome in
            switch getMessagesOutcome {
            case .failure(let error):
                withAnimation {
                    loginInProgress = false
                }
                if error == .remoteDeviceChanged {
                    showingResetDeviceSheet = true
                } else {
                    appState.displayedError = IdentifiableError(error)
                }
            case .success:
                handleCheckSubscriptionStatus(newUser: newUser)
            }
        }
    }
    
    func handleCheckSubscriptionStatus(newUser: LoggedInUser) -> Void {
        
        withAnimation {
            loginInProgress = true
        }
        
        let subscriptionController = appState.subscriptionController
        
        subscriptionController.verifyReceipt() { verifyResult in
            
            withAnimation {
                loginInProgress = false
            }
            
            switch verifyResult {
            case.failure(let error):
                print(error)
                // Don't display error here as user may genuinely not be a subscriber
                DispatchQueue.main.async {
                    if error == .expiredPurchase {
                        appState.displayedError = IdentifiableError(error)
                    }
                    withAnimation {
                        appState.loggedInUser = newUser
                    }
                }
            case .success(let expiryDate):
                DispatchQueue.main.async {
                    newUser.subscriptionExpiryDate = expiryDate
                    withAnimation {
                        appState.loggedInUser = newUser
                    }
                }
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
        
        withAnimation {
            loginInProgress = true
        }
        
        messagingController.deleteDevice(
            userName: storedNewUser.userName,
            serverAddress: storedNewUser.serverAddress,
            authToken: storedNewUser.authCode) {
            deleteDeviceOutcome in
            switch deleteDeviceOutcome {
            case .failure(let error):
                withAnimation {
                    loginInProgress = false
                }
                appState.displayedError = IdentifiableError(error)
            case .success():
                handleCreateDevice(newUser: storedNewUser)
            }
        }
    }
    
    func submitTwoFactor(_ twoFactorCode: String) {
        withAnimation {
            loginInProgress = true
        }
        authorisationController.submitTwoFactor(
            username: username,
            code: twoFactorCode,
            ephemeralToken: ephemeralCode ?? "unknown",
            serverAddress: customAuthServer) { outcome in
            DispatchQueue.main.async {
                twoFactorModalVisible = false
                switch outcome {
                case .success(let newUser):
                    storedNewUser = newUser
                    handleCreateDevice(newUser: newUser)
                case .failure(let error):
                    withAnimation {
                        loginInProgress = false
                    }
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
                performLogin: handleLogin
            )
            Text("").hidden().actionSheet(isPresented: $showingDeleteDeviceSheet) {
                ActionSheet(
                    title: Text("Device already exists"),
                    message: Text("This account already has a registered device on the server. If you delete it you will no longer be able to log in from devices you have previously used. Do you still wish to delete the device on the server? This is irreversible."),
                    buttons: [
                        .cancel(),
                        .destructive(Text("Delete device from server"), action: handleDeleteDeviceThenLogin)
                    ]
                )
            }
            Text("").hidden().actionSheet(isPresented: $showingResetDeviceSheet) {
                ActionSheet(
                    title: Text("Server does not match"),
                    message: Text("The device registered on the server does not match the details stored on this device. This happens when you have logged on from another device. Do you wish to delete the details on the sever and this device? This is irreversible, but necessary to continue."),
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
                    message: Text("If \(resetPasswordRequestedEmail) is registered as a user on the server then a reset password email will have been sent to them."),
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

