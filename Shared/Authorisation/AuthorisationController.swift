//
//  AuthorisationController.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 06/12/2020.
//

import Foundation

public class AuthorisationController {
    
    func login(username: String, password: String, serverAddress: String, appState: AppState) {
        if username == "testUser" && password == "password" {
            appState.loggedInUser = LoggedInUser(
                userName: username,
                deviceName: password,
                serverAddress: serverAddress,
                authCode: "testAuthString"
            )
        } else {
            appState.loggedInUser = nil
            appState.displayedError = AuthorisationError.invalidPassword
        }
    }
    
}
