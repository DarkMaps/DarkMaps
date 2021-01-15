//
//  AuthorisationController.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 06/12/2020.
//

import Foundation

public struct AuthorisationController {
    
    var simpleSignalSwiftAuthAPI = SimpleSignalSwiftAuthAPI()
    
    func register(username: String, password: String, serverAddress: String, completionHandler: @escaping (Result<Void, SSAPIAuthRegisterError>) -> ()) {
        print("Attempting Register")
        DispatchQueue.global(qos: .utility).async {
            let response = self.simpleSignalSwiftAuthAPI.register(username: username, password: password, serverAddress: serverAddress)
            DispatchQueue.main.async {
                switch response {
                    case .success:
                        print("Register Successful")
                        completionHandler(.success(()))
                    case let .failure(error):
                        print("Register Unsuccessful")
                        completionHandler(.failure(error))
                    }
            }
        }
    }
    
    func login(username: String, password: String, serverAddress: String, completionHandler: @escaping (_: LoginOutcome) -> ()) {
        print("Attempting Login")
        DispatchQueue.global(qos: .utility).async {
            let response = self.simpleSignalSwiftAuthAPI.login(username: username, password: password, serverAddress: serverAddress)
            DispatchQueue.main.async {
                switch response {
                    case let .success(data):
                        let newUser =  LoggedInUser(
                            userName: username,
                            deviceId: 1,
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
    
    func resetPassword(username: String, serverAddress: String, completionHandler: @escaping (Result<Void, SSAPIAuthResetPasswordError>) -> ()) {
        print("Attempting Reset Password")
        DispatchQueue.global(qos: .utility).async {
            let response = self.simpleSignalSwiftAuthAPI.resetPassword(username: username, serverAddress: serverAddress)
            DispatchQueue.main.async {
                switch response {
                    case .success:
                        print("Reset Password Successful")
                        completionHandler(.success(()))
                    case let .failure(error):
                        print("Reset Password Unsuccessful")
                        completionHandler(.failure(error))
                    }
            }
        }
    }
    
    func submitTwoFactor(username: String, code: String, ephemeralToken: String, serverAddress: String, completionHandler: @escaping (_: Result<LoggedInUser, SSAPIAuthSubmit2FAError>) -> ()) {
        print("Submit 2FA")
        DispatchQueue.global(qos: .utility).async {
            let response = self.simpleSignalSwiftAuthAPI.submitTwoFactorAuthentication(ephemeralToken: ephemeralToken, submit2FACode: code, serverAddress: serverAddress)
            DispatchQueue.main.async {
                switch response {
                    case let .success(data):
                        let newUser =  LoggedInUser(
                            userName: username,
                            deviceId: 1,
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
    
    func logUserOut(authToken: String, serverAddress: String, completionHandler: @escaping (_: Result<Void, SSAPIAuthLogOutError>) -> ()) {
        print("Log Out")
        DispatchQueue.global(qos: .utility).async {
            let response = self.simpleSignalSwiftAuthAPI.logOut(authToken: authToken, serverAddress: serverAddress)
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
    
    func request2FAQRCode(authToken: String, serverAddress: String, completionHandler: @escaping (_: Result<String, SSAPIAuthActivate2FAError>) -> ()) {
        print("Request 2FA QR Code")
        DispatchQueue.global(qos: .utility).async {
            let response = self.simpleSignalSwiftAuthAPI.activateTwoFactorAuthentication(authToken: authToken, mfaMethodName: "app", serverAddress: serverAddress)
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
                        print(error)
                        completionHandler(.failure(error))
                }
            }
        }
    }
    
    func confirm2FA(code: String, authToken: String, serverAddress: String, completionHandler: @escaping (_: Result<[String], SSAPIAuthConfirm2FAError>) -> ()) {
        print("Confirm 2FA")
        DispatchQueue.global(qos: .utility).async {
            let response = self.simpleSignalSwiftAuthAPI.confirmTwoFactorAuthentication(
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
                        print(error)
                        completionHandler(.failure(error))
                }
            }
        }
    }
    
    func deactivate2FA(code: String, authToken: String, serverAddress: String, completionHandler: @escaping (_: Result<Void, SSAPIAuthDeactivate2FAError>) -> ()) {
        print("Deativate 2FA")
        DispatchQueue.global(qos: .utility).async {
            let response = self.simpleSignalSwiftAuthAPI.deactivateTwoFactorAuthentication(
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
    
    func deleteUserAccount(currentPassword: String, authToken: String, serverAddress: String, completionHandler: @escaping (_: Result<Void, SSAPIAuthDeleteUserAccountError>) -> ()) {
        print("Delete User Account")
        print(currentPassword)
        DispatchQueue.global(qos: .utility).async {
            let response = self.simpleSignalSwiftAuthAPI.deleteUserAccount(
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
