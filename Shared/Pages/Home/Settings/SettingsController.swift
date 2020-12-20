//
//  SettingsController.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 08/12/2020.
//
import SwiftUI

struct SettingsController: View {
    
    @EnvironmentObject var appState: AppState
    
    @Environment(\.presentationMode) var presentation
    
    @State var activate2FAModalIsShowing = false
    @State var QRCodeFor2FA: String? = nil
    @State var confirm2FACode = ""
    @State var deactivate2FAModalIsShowing = false
    @State var deactivate2FACode = ""
    @State var passwordAlertShowing = false
    @State var currentPassword = ""
    @State var backupCodesAlertShowing = false
    @State var backupCodes: IdentifiableBackupCodes?
    @State var actionInProgress: ActionInProgress? = nil
    
    var authorisationController = AuthorisationController()
    
    func logUserOut() {
        actionInProgress = .logUserOut
        authorisationController.logUserOut(authToken: appState.loggedInUser?.authCode ?? "unknown", serverAddress: appState.loggedInUser?.serverAddress ?? "unknown") { result in
            actionInProgress = nil
            switch result {
            case .success():
                appState.loggedInUser = nil
            case .failure(let error):
                appState.displayedError = IdentifiableError(error)
                appState.loggedInUser = nil
            }
        }
    }
    
    func obtain2FAQRCode() {
        actionInProgress = .obtain2FAQRCode
        authorisationController.request2FAQRCode(authToken: appState.loggedInUser?.authCode ?? "unknown", serverAddress: appState.loggedInUser?.serverAddress ?? "unknown") { result in
            actionInProgress = nil
            switch result {
            case .success(let QRCode):
                self.QRCodeFor2FA = QRCode
            case .failure(let error):
                activate2FAModalIsShowing = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                    appState.displayedError = IdentifiableError(error)
                })
            }
        }
    }
    
    func confirm2FA() {
        actionInProgress = .confirm2FA
        authorisationController.confirm2FA(code: confirm2FACode, authToken: appState.loggedInUser?.authCode ?? "unknown", serverAddress: appState.loggedInUser?.serverAddress ?? "unknown") { result in
            actionInProgress = nil
            activate2FAModalIsShowing = false
            switch result {
            case .success(let backupCodes):
                self.backupCodes = IdentifiableBackupCodes(codes: backupCodes)
                appState.loggedInUser?.is2FAUser = true
            case .failure(let error):
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                    appState.displayedError = IdentifiableError(error)
                })
            }
        }
    }
    
    func deactivate2FA() {
        actionInProgress = .deactivate2FA
        authorisationController.deactivate2FA(code: deactivate2FACode, authToken: appState.loggedInUser?.authCode ?? "unknown", serverAddress: appState.loggedInUser?.serverAddress ?? "unknown") { result in
            actionInProgress = nil
            deactivate2FAModalIsShowing = false
            switch result {
            case .success():
                appState.loggedInUser?.is2FAUser = false
            case .failure(let error):
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                    appState.displayedError = IdentifiableError(error)
                })
            }
        }
    }
    
    func deleteUserAccount() {
        actionInProgress = .deleteUserAccount
        authorisationController.deleteUserAccount(currentPassword: currentPassword, authToken: appState.loggedInUser?.authCode ?? "unknown", serverAddress: appState.loggedInUser?.serverAddress ?? "unknown") { result in
            actionInProgress = nil
            switch result {
            case .success():
                appState.loggedInUser = nil
            case .failure(let error):
                appState.displayedError = IdentifiableError(error)
            }
        }
    }
    
    var body: some View {
        ZStack {
            SettingsView(
                activate2FAModalIsShowing: $activate2FAModalIsShowing,
                deactivate2FAModalIsShowing: $deactivate2FAModalIsShowing,
                passwordAlertShowing: $passwordAlertShowing,
                loggedInUser: $appState.loggedInUser,
                actionInProgress: $actionInProgress,
                logUserOut: logUserOut
            )
            Text("").hidden().sheet(isPresented: $activate2FAModalIsShowing, onDismiss: {
                if backupCodes != nil {
                    self.backupCodesAlertShowing = true
                }
            }, content: {
                Activate2FAModal(
                    confirm2FACode: $confirm2FACode,
                    QRCodeFor2FA: $QRCodeFor2FA,
                    actionInProgress: $actionInProgress,
                    obtain2FAQRCode: obtain2FAQRCode,
                    confirm2FA: confirm2FA)
            })
            Text("").hidden().sheet(isPresented: $deactivate2FAModalIsShowing, content: {
                Deactivate2FAModal(
                    deactivate2FACode: $deactivate2FACode,
                    actionInProgress: $actionInProgress,
                    deactivate2FA: deactivate2FA)
            })
            Text("").hidden().textFieldAlert(
                isShowing: $passwordAlertShowing,
                text: $currentPassword,
                title: "Password Required",
                secureField: true,
                onDismiss: deleteUserAccount
            )
            Text("").hidden().alert(isPresented: $backupCodesAlertShowing) { () -> Alert in
                Alert(
                    title: Text("Backup Codes"),
                    message: Text("Store these backup codes in a safe place:\n\n\((backupCodes?.codes ?? []).joined(separator: "\n"))"),
                    dismissButton: .cancel()
                )
            }
            
        }
        
    }
}

struct IdentifiableBackupCodes: Identifiable {
    var id = UUID()
    var codes: [String]
}

enum ActionInProgress {
    case obtain2FAQRCode, confirm2FA, deactivate2FA, logUserOut, deleteUserAccount
}
