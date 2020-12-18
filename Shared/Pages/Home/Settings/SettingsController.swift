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
    @State var activate2FACode = ""
    @State var deactivate2FAModalIsShowing = false
    @State var deactivate2FACode = ""
    
    var authorisationController = AuthorisationController()
    
    func logUserOut() {
        authorisationController.logUserOut(appState: appState)
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
    
    func activate2FA() {
        authorisationController.activate2FA(code: activate2FACode, appState: appState)
        activate2FAModalIsShowing = false
    }
    
    func deactivate2FA() {
        authorisationController.deactivate2FA(code: deactivate2FACode, appState: appState)
        deactivate2FAModalIsShowing = false
    }
    func deleteUserAccount() {
        authorisationController.deleteUserAccount(appState: appState)
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
                    activate2FACode: $activate2FACode,
                    QRCodeFor2FA: $QRCodeFor2FA,
                    obtain2FAQRCode: obtain2FAQRCode,
                    activate2FA: activate2FA)
            })
            Text("").hidden().sheet(isPresented: $deactivate2FAModalIsShowing, content: {
                Deactivate2FAModal(
                    deactivate2FACode: $deactivate2FACode,
                    deactivate2FA: deactivate2FA)
            })
        }
        
    }
}
