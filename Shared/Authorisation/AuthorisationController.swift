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
                print(response)
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
                        case .url:
                            completionHandler(.failure(AuthorisationError.invalidUrl))
                        case .clientJson:
                            completionHandler(.failure(AuthorisationError.badFormat))
                        case .serverError, .serverJson:
                            completionHandler(.failure(AuthorisationError.serverError))
                        case let .server(errorString):
                            if (errorString == "Unable to login with provided credentials.") {
                                completionHandler(.failure(AuthorisationError.invalidCredentials))
                            } else {
                                completionHandler(.failure(AuthorisationError.serverError))
                            }
                        case .requestThrottled:
                            completionHandler(.failure(AuthorisationError.requestThrottled))
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
