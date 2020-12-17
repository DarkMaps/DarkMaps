//
//  AuthorisationController.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 06/12/2020.
//

import Foundation

public class AuthorisationController {
    
    func login(username: String, password: String, serverAddress: String, appState: AppState) -> loginOutcome{
        print("Attempting Login")
        if username == "testUser" && password == "password" {
            appState.loggedInUser = LoggedInUser(
                userName: username,
                deviceName: "fakeDeviceName",
                serverAddress: serverAddress,
                authCode: "testAuthString",
                is2FAUser: false
            )
            print("Login Successful")
            return .success
        } else if username == "testUser2FA" && password == "password" {
            print("2FA Required")
            return .twoFactorRequired("fakeEphemeralCode")
        } else {
            appState.loggedInUser = nil
            appState.displayedError = IdentifiableError(AuthorisationError.invalidPassword)
            print("Login Unsuccessful")
            return .failure
        }
    }
    
    func submitTwoFactor(ephemeralCode: String, twoFactorCode: String, username: String, serverAddress: String, appState: AppState) {
        appState.loggedInUser = LoggedInUser(
            userName: username,
            deviceName: "fakeDeviceName",
            serverAddress: serverAddress,
            authCode: "testAuthString",
            is2FAUser: true
        )
    }
    
    func logUserOut(appState: AppState) {
        print("Log Out")
        appState.loggedInUser = nil
    }
    
    func request2FAQRCode() -> String {
        print("Request 2FA QR Code")
        return "jkhsdgjhsjdghjsghsk"
    }
    
    func activate2FA(code: String, appState: AppState) {
        print("Activate 2FA")
        appState.loggedInUser = LoggedInUser(
            userName: appState.loggedInUser!.userName,
            deviceName: appState.loggedInUser!.deviceName,
            serverAddress: appState.loggedInUser!.serverAddress,
            authCode: appState.loggedInUser!.authCode,
            is2FAUser: true
        )
    }
    
    func deactivate2FA(code: String, appState: AppState) {
        print("Deactivate 2FA")
        appState.loggedInUser = LoggedInUser(
            userName: appState.loggedInUser!.userName,
            deviceName: appState.loggedInUser!.deviceName,
            serverAddress: appState.loggedInUser!.serverAddress,
            authCode: appState.loggedInUser!.authCode,
            is2FAUser: false
        )
    }
    
    func deleteUserAccount(appState: AppState) {
        print("Delete User Account")
        appState.loggedInUser = nil
    }
    
}
