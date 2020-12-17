//
//  AuthorisationController.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 06/12/2020.
//

import Foundation

public class AuthorisationController {
    
    var simpleSignalSwiftAPI = SimpleSignalSwiftAPI()
    
    func login(username: String, password: String, serverAddress: String, completionHandler: @escaping (_: LoginOutcome) -> ()) {
        print("Attempting Login")
        DispatchQueue.global(qos: .utility).async {
            let response = self.simpleSignalSwiftAPI.login(username: username, password: password, serverAddress: serverAddress)
            DispatchQueue.main.async {
                switch response {
                    case let .success(data):
                        let newUser =  LoggedInUser(
                            userName: username,
                            deviceName: "fakeDeviceName",
                            serverAddress: serverAddress,
                            authCode: data.authToken,
                            is2FAUser: false
                        )
                        print("Login Successful")
                        completionHandler(.success(newUser))
                    case let .failure(error):
                        print(error)
                        print("Login Unsuccessful")
                        completionHandler(.failure(AuthorisationError.invalidPassword))
                    }
            }
        }
//        if username == "testUser" && password == "password" {
//            appState.loggedInUser = LoggedInUser(
//                userName: username,
//                deviceName: "fakeDeviceName",
//                serverAddress: serverAddress,
//                authCode: "testAuthString",
//                is2FAUser: false
//            )
//            print("Login Successful")
//            return .success
//        } else if username == "testUser2FA" && password == "password" {
//            print("2FA Required")
//            return .twoFactorRequired("fakeEphemeralCode")
//        } else {
//            appState.loggedInUser = nil
//            appState.displayedError = IdentifiableError(AuthorisationError.invalidPassword)
//            print("Login Unsuccessful")
//            return .failure
//        }
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
