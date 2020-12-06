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
                authCode: "testAuthString"
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
            authCode: "testAuthString"
        )
    }
    
}
