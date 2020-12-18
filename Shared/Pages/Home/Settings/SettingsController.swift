//
//  SettingsController.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 08/12/2020.
//
import SwiftUI

struct SettingsController: View {
    
    @EnvironmentObject var appState: AppState
    
    @State var activate2FAModalIsShowing = false
    @State var QRCodeFor2FA = ""
    @State var confirm2FACode = ""
    @State var deactivate2FAModalIsShowing = false
    @State var deactivate2FACode = ""
    
    var authorisationController = AuthorisationController()
    
    func logUserOut() {
        authorisationController.logUserOut(authToken: appState.loggedInUser?.authCode ?? "unknown", serverAddress: appState.loggedInUser?.serverAddress ?? "unknown") { result in
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
        authorisationController.request2FAQRCode(authToken: appState.loggedInUser?.authCode ?? "unknown", serverAddress: appState.loggedInUser?.serverAddress ?? "unknown") { result in
            switch result {
            case .success(let QRCode):
                self.QRCodeFor2FA = QRCode
            case .failure(let error):
                appState.displayedError = IdentifiableError(error)
            }
        }
    }
    
    func confirm2FA() {
        authorisationController.confirm2FA(code: confirm2FACode, authToken: appState.loggedInUser?.authCode ?? "unknown", serverAddress: appState.loggedInUser?.serverAddress ?? "unknown") { result in
            switch result {
            case .success(let TODO_NEEDS_IMPLEMENTING_backupCodes):
                //Handle backupcodes
                activate2FAModalIsShowing = false
            case .failure(let error):
                appState.displayedError = IdentifiableError(error)
                activate2FAModalIsShowing = false
            }
        }
    }
    
    func deactivate2FA() {
        authorisationController.deactivate2FA(code: deactivate2FACode, authToken: appState.loggedInUser?.authCode ?? "unknown", serverAddress: appState.loggedInUser?.serverAddress ?? "unknown") { result in
            switch result {
            case .success():
                deactivate2FAModalIsShowing = false
            case .failure(let error):
                appState.displayedError = IdentifiableError(error)
                deactivate2FAModalIsShowing = false
            }
        }
    }
    
    func deleteUserAccount() {
        authorisationController.deleteUserAccount(currentPassword: "TODO_NEEDS_IMPLEMENTING", authToken: appState.loggedInUser?.authCode ?? "unknown", serverAddress: appState.loggedInUser?.serverAddress ?? "unknown") { result in
            switch result {
            case .success():
                appState.loggedInUser = nil
            case .failure(let error):
                appState.displayedError = IdentifiableError(error)
                appState.loggedInUser = nil
            }
        }
    }
    
    var body: some View {
        ZStack {
            SettingsView(
                activate2FAModalIsShowing: $activate2FAModalIsShowing,
                deactivate2FAModalIsShowing: $deactivate2FAModalIsShowing,
                loggedInUser: $appState.loggedInUser,
                logUserOut: logUserOut,
                deleteUserAccount: deleteUserAccount
            )
            Text("").hidden().sheet(isPresented: $activate2FAModalIsShowing, content: {
                Activate2FAModal(
                    confirm2FACode: $confirm2FACode,
                    QRCodeFor2FA: $QRCodeFor2FA,
                    obtain2FAQRCode: obtain2FAQRCode,
                    confirm2FA: confirm2FA)
            })
            Text("").hidden().sheet(isPresented: $deactivate2FAModalIsShowing, content: {
                Deactivate2FAModal(
                    deactivate2FACode: $deactivate2FACode,
                    deactivate2FA: deactivate2FA)
            })
        }
        
    }
}
