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
    
    func submitTwoFactor(username: String, code: String, ephemeralToken: String, serverAddress: String, completionHandler: @escaping (_: Result<LoggedInUser, SSAPISubmit2FAError>) -> ()) {
        print("Submit 2FA")
        DispatchQueue.global(qos: .utility).async {
            let response = self.simpleSignalSwiftAPI.submitTwoFactorAuthentication(ephemeralToken: ephemeralToken, submit2FACode: code, serverAddress: serverAddress)
            DispatchQueue.main.async {
                switch response {
                    case let .success(data):
                        let newUser =  LoggedInUser(
                            userName: username,
                            serverAddress: serverAddress,
                            authCode: data.authToken,
                            is2FAUser: true
                        )
                        print("2FA Login Successful")
                        completionHandler(.success(newUser))
                    case let .failure(error):
                        print("Request Unsuccessful")
                        completionHandler(.failure(error))
                }
            }
        }
    }
    
    func logUserOut(authToken: String, serverAddress: String, completionHandler: @escaping (_: Result<Void, SSAPILogOutError>) -> ()) {
        print("Log Out")
        DispatchQueue.global(qos: .utility).async {
            let response = self.simpleSignalSwiftAPI.logOut(authToken: authToken, serverAddress: serverAddress)
            DispatchQueue.main.async {
                switch response {
                    case .success:
                        completionHandler(.success(()))
                    case let .failure(error):
                        print("Request Unsuccessful")
                        completionHandler(.failure(error))
                }
            }
        }
    }
    
    func request2FAQRCode(authToken: String, serverAddress: String, completionHandler: @escaping (_: Result<String, SSAPIActivate2FAError>) -> ()) {
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
    
    func confirm2FA(code: String, authToken: String, serverAddress: String, completionHandler: @escaping (_: Result<[String], SSAPIConfirm2FAError>) -> ()) {
        print("Confirm 2FA")
        DispatchQueue.global(qos: .utility).async {
            let response = self.simpleSignalSwiftAPI.confirmTwoFactorAuthentication(
                authToken: authToken,
                mfaMethodName: "app",
                confirm2FACode: code,
                serverAddress: serverAddress)
            DispatchQueue.main.async {
                switch response {
                    case let .success(data):
                        completionHandler(.success(data.backupCodes))
                    case let .failure(error):
                        print("Request Unsuccessful")
                        completionHandler(.failure(error))
                }
            }
        }
    }
    
    func deactivate2FA(code: String, authToken: String, serverAddress: String, completionHandler: @escaping (_: Result<Void, SSAPIDeactivate2FAError>) -> ()) {
        print("Deativate 2FA")
        DispatchQueue.global(qos: .utility).async {
            let response = self.simpleSignalSwiftAPI.deactivateTwoFactorAuthentication(
                authToken: authToken,
                mfaMethodName: "app",
                confirm2FACode: code,
                serverAddress: serverAddress)
            DispatchQueue.main.async {
                switch response {
                    case .success():
                        completionHandler(.success(()))
                    case let .failure(error):
                        print("Request Unsuccessful")
                        completionHandler(.failure(error))
                }
            }
        }
    }
    
    func deleteUserAccount(currentPassword: String, authToken: String, serverAddress: String, completionHandler: @escaping (_: Result<Void, SSAPIDeleteUserAccountError>) -> ()) {
        print("Delete User Account")
        DispatchQueue.global(qos: .utility).async {
            let response = self.simpleSignalSwiftAPI.deleteUserAccount(
                currentPassword: currentPassword,
                authToken: authToken,
                serverAddress: serverAddress)
            DispatchQueue.main.async {
                switch response {
                    case .success():
                        completionHandler(.success(()))
                    case let .failure(error):
                        print("Request Unsuccessful")
                        completionHandler(.failure(error))
                }
            }
        }
    }
    
}
