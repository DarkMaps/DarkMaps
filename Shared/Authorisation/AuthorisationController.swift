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
                            serverAddress: serverAddress,
                            authCode: data.authToken,
                            is2FAUser: false
                        )
                        print("Login Successful")
                        completionHandler(.success(newUser))
                    case let .failure(error):
                        print("Login Unsuccessful")
                        switch error {
                        case let .needsTwoFactorAuthentication(ephemeralToken):
                            completionHandler(.twoFactorRequired(ephemeralToken))
                        default:
                            completionHandler(.failure(error))
                        }
                    }
            }
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
    
    func BUILDINGFORAPIrequest2DAQRCode(authToken: String, serverAddress: String, completionHandler: @escaping (_: Result<String, SSAPIActivate2FAError>) -> ()) {
        print("Request 2FA QR Code")
        DispatchQueue.global(qos: .utility).async {
            let response = self.simpleSignalSwiftAPI.activateTwoFactorAuthentication(authToken: authToken, mfaMethodName: "app", serverAddress: serverAddress)
            DispatchQueue.main.async {
                switch response {
                    case let .success(data):
                        guard data.qrLink != nil else {
                            completionHandler(.failure(.badResponseFromServer))
                            return
                        }
                        completionHandler(.success(data.qrLink!))
                    case let .failure(error):
                        print("Request Unsuccessful")
                        completionHandler(.failure(error))
                }
            }
        }
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
