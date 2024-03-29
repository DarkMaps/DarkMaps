//
//  SimpleSignalSwiftAPI.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 17/12/2020.
//

import Foundation

//https://michaellong.medium.com/how-to-chain-api-calls-using-swift-5s-new-result-type-and-gcd-56025b51033c

public struct SimpleSignalSwiftAuthAPI{
    
    private let notificationCentre = NotificationCenter.default
    
    var timeoutDuration: DispatchTime {
        return .now() + 5
    }
    
    public func register(username: String, password: String, serverAddress: String) -> Result<Void, SSAPIAuthRegisterError> {
        
        let path = "\(serverAddress)/v1/auth/users/"
        guard let url = URL(string: path) else {
            return .failure(.invalidUrl)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let json = [
            "email": username,
            "password": password
        ]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: json, options: []) else {
            return .failure(.badFormat)
        }
        
        var result: Result<Void, SSAPIAuthRegisterError>!
        
        let semaphore = DispatchSemaphore(value: 0)
        
        URLSession.shared.uploadTask(with: request, from: jsonData) { (data, response, error) in
            
            if error != nil || data == nil {
                result = .failure(.badResponseFromServer)
                semaphore.signal()
                return
            }

            guard let response = response as? HTTPURLResponse else {
                result = .failure(.badResponseFromServer)
                semaphore.signal()
                return
            }
            
            guard response.statusCode == 201 else {
                if response.statusCode == 400 {
                    do {
                        // For 400 errors we need to parse the returned JSON and determine the type of error
                        let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
                        if let nonFieldErrors = (json?["non_field_errors"] as? [String]) {
                            if nonFieldErrors.contains("A user with that email address already exists.") {
                                result = .failure(.emailExists)
                            } else {
                                result = .failure(.serverError)
                            }
                        } else {
                            result = .failure(.serverError)
                        }
                    } catch {
                        result = .failure(.badResponseFromServer)
                    }
                } else if response.statusCode == 429 {
                    result = .failure(.requestThrottled)
                } else {
                    result = .failure(.serverError)
                }
                semaphore.signal()
                return
            }
            
            result = .success(())
            
            semaphore.signal()
            
        }.resume()
        
        if semaphore.wait(timeout: timeoutDuration) == .timedOut {
            result = .failure(.timeout)
        }
        
        return result
        
    }
    
    public func login(username: String, password: String, serverAddress: String) -> Result<SSAPILoginResponse, SSAPIAuthLoginError> {
        
        let path = "\(serverAddress)/v1/auth/login/"
        guard let url = URL(string: path) else {
            return .failure(.invalidUrl)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let json = [
            "email": username,
            "password": password
        ]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: json, options: []) else {
            return .failure(.badFormat)
        }
        
        var result: Result<SSAPILoginResponse, SSAPIAuthLoginError>!
        
        let semaphore = DispatchSemaphore(value: 0)
        
        URLSession.shared.uploadTask(with: request, from: jsonData) { (data, response, error) in
            
            if error != nil || data == nil {
                result = .failure(.badResponseFromServer)
                semaphore.signal()
                return
            }

            guard let response = response as? HTTPURLResponse else {
                result = .failure(.badResponseFromServer)
                semaphore.signal()
                return
            }
            
            guard response.statusCode == 200 else {
                if response.statusCode == 400 {
                    do {
                        // For 400 errors we need to parse the returned JSON and determine the type of error
                        let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
                        if let nonFieldErrors = (json?["non_field_errors"] as? [String]) {
                            if nonFieldErrors.contains("Unable to login with provided credentials.") {
                                result = .failure(.invalidCredentials)
                            } else {
                                result = .failure(.serverError)
                            }
                        } else {
                            result = .failure(.serverError)
                        }
                    } catch {
                        result = .failure(.badResponseFromServer)
                    }
                } else if response.statusCode == 429 {
                    result = .failure(.requestThrottled)
                } else {
                    result = .failure(.serverError)
                }
                semaphore.signal()
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let decodedLoginResponse = try decoder.decode(SSAPILoginResponse.self, from: data!)
                result = .success(decodedLoginResponse)
            } catch {
                do {
                    // 200 responses are stil returned when 2FA is required
                    // Here we parse the data returned to find the ephemeral token and return it
                    let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
                    if let ephemeralToken = (json?["ephemeral_token"] as? String) {
                        result = .failure(.needsTwoFactorAuthentication(ephemeralToken))
                    } else {
                        result = .failure(.badResponseFromServer)
                    }
                } catch {
                    result = .failure(.badResponseFromServer)
                }
            }
            
            semaphore.signal()
            
        }.resume()
        
        if semaphore.wait(timeout: timeoutDuration) == .timedOut {
            result = .failure(.timeout)
        }
        
        return result
        
    }
    
    public func resetPassword(username: String, serverAddress: String) -> Result<Void, SSAPIAuthResetPasswordError> {
        
        let path = "\(serverAddress)/v1/auth/users/reset_password/"
        guard let url = URL(string: path) else {
            return .failure(.invalidUrl)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let json = [
            "email": username
        ]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: json, options: []) else {
            return .failure(.badFormat)
        }
        
        var result: Result<Void, SSAPIAuthResetPasswordError>!
        
        let semaphore = DispatchSemaphore(value: 0)
        
        URLSession.shared.uploadTask(with: request, from: jsonData) { (data, response, error) in
            
            if error != nil || data == nil {
                result = .failure(.badResponseFromServer)
                semaphore.signal()
                return
            }

            guard let response = response as? HTTPURLResponse else {
                result = .failure(.badResponseFromServer)
                semaphore.signal()
                return
            }
            
            guard response.statusCode == 204 else {
                print(response.statusCode)
                print(response)
                if response.statusCode == 400 {
                    result = .failure(.badResponseFromServer)
                } else if response.statusCode == 429 {
                    result = .failure(.requestThrottled)
                } else {
                    result = .failure(.serverError)
                }
                semaphore.signal()
                return
            }
            
            result = .success(())
            
            semaphore.signal()
            
        }.resume()
        
        if semaphore.wait(timeout: timeoutDuration) == .timedOut {
            result = .failure(.timeout)
        }
        
        return result
        
    }
    
    public func submitTwoFactorAuthentication(ephemeralToken: String, submit2FACode: String, serverAddress: String) -> Result<SSAPISubmit2FAResponse, SSAPIAuthSubmit2FAError> {
        
        let path = "\(serverAddress)/v1/auth/login/code/"
        guard let url = URL(string: path) else {
            return .failure(.invalidUrl)
        }
        
        guard let submit2FACodeInt = Int(submit2FACode) else {
            return .failure(.badFormat)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let json = [
            "ephemeral_token": ephemeralToken,
            "code": submit2FACodeInt
        ] as [String : Any]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: json, options: []) else {
            return .failure(.badFormat)
        }
        
        var result: Result<SSAPISubmit2FAResponse, SSAPIAuthSubmit2FAError>!
        
        let semaphore = DispatchSemaphore(value: 0)
        
        URLSession.shared.uploadTask(with: request, from: jsonData) { (data, response, error) in
            
            if error != nil || data == nil {
                result = .failure(.serverError)
                semaphore.signal()
                return
            }

            guard let response = response as? HTTPURLResponse else {
                result = .failure(.serverError)
                semaphore.signal()
                return
            }
            
            guard response.statusCode == 200 else {
                if response.statusCode == 400 {
                    do {
                        // For 400 errors we need to parse the returned JSON and determine the type of error
                        let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
                        if let nonFieldErrors = (json?["non_field_errors"] as? [String]) {
                            if nonFieldErrors.contains("Invalid or expired code.") {
                                result = .failure(.invalidCode)
                            } else if nonFieldErrors.contains("Invalid or expired token.") {
                                result = .failure(.invalidToken)
                            } else {
                                result = .failure(.serverError)
                            }
                        } else {
                            result = .failure(.serverError)
                        }
                    } catch {
                        result = .failure(.badResponseFromServer)
                    }
                } else if response.statusCode == 401 {
                    self.notificationCentre.post(name: .communicationController_Unauthorised, object: nil)
                    result = .failure(.unauthorised)
                } else if response.statusCode == 429 {
                    result = .failure(.requestThrottled)
                } else {
                    result = .failure(.serverError)
                }
                semaphore.signal()
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let decodedResponse = try decoder.decode(SSAPISubmit2FAResponse.self, from: data!)
                result = .success(decodedResponse)
            } catch {
                result = .failure(.badResponseFromServer)
            }
            
            semaphore.signal()
            
        }.resume()
        
        if semaphore.wait(timeout: timeoutDuration) == .timedOut {
            result = .failure(.timeout)
        }
        
        return result
        
    }
    
    public func activateTwoFactorAuthentication(authToken: String, mfaMethodName: String, serverAddress: String) -> Result<SSAPIActivate2FAResponse, SSAPIAuthActivate2FAError> {
        
        let path = "\(serverAddress)/v1/auth/\(mfaMethodName)/activate/"
        guard let url = URL(string: path) else {
            return .failure(.invalidUrl)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Token \(authToken)", forHTTPHeaderField: "Authorization")
        let json: [String: Any] = [:]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: json, options: []) else {
            return .failure(.badFormat)
        }
        
        var result: Result<SSAPIActivate2FAResponse, SSAPIAuthActivate2FAError>!
        
        let semaphore = DispatchSemaphore(value: 0)
        
        URLSession.shared.uploadTask(with: request, from: jsonData) { (data, response, error) in
            
            if error != nil || data == nil {
                result = .failure(.serverError)
                semaphore.signal()
                return
            }

            guard let response = response as? HTTPURLResponse else {
                result = .failure(.serverError)
                semaphore.signal()
                return
            }
            
            guard response.statusCode == 200 else {
                if response.statusCode == 400 {
                    // For 400 errors we need to parse the returned JSON and determine the type of error
                    do {
                        let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
                        if let errorsObject = (json?["error"] as? [String]) {
                            if errorsObject.contains("MFA method already active.") {
                                result = .failure(.twoFactorAlreadyExists)
                            } else {
                                result = .failure(.serverError)
                            }
                        } else {
                            result = .failure(.serverError)
                        }
                    } catch {
                        result = .failure(.badResponseFromServer)
                    }
                } else if response.statusCode == 401 {
                    self.notificationCentre.post(name: .communicationController_Unauthorised, object: nil)
                    result = .failure(.unauthorised)
                } else if response.statusCode == 403 {
                    // A 403 response probably means the mfaMethodName was unrecognised
                    result = .failure(.possibleIncorrectMFAMethodName)
                } else if response.statusCode == 429 {
                    result = .failure(.requestThrottled)
                } else {
                    result = .failure(.serverError)
                }
                semaphore.signal()
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let decodedLoginResponse = try decoder.decode(SSAPIActivate2FAResponse.self, from: data!)
                result = .success(decodedLoginResponse)
            } catch {
                result = .failure(.badResponseFromServer)
            }
            
            semaphore.signal()
            
        }.resume()
        
        if semaphore.wait(timeout: timeoutDuration) == .timedOut {
            result = .failure(.timeout)
        }
        
        return result
        
    }
    
    public func confirmTwoFactorAuthentication(authToken: String, mfaMethodName: String, confirm2FACode: String, serverAddress: String) -> Result<SSAPIConfirm2FAResponse, SSAPIAuthConfirm2FAError> {
        
        let path = "\(serverAddress)/v1/auth/\(mfaMethodName)/activate/confirm/"
        guard let url = URL(string: path) else {
            return .failure(.invalidUrl)
        }
        
        guard let confirm2FACodeInt = Int(confirm2FACode) else {
            return .failure(.badFormat)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Token \(authToken)", forHTTPHeaderField: "Authorization")
        let json = [
            "code": confirm2FACodeInt
        ]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: json, options: []) else {
            return .failure(.badFormat)
        }
        
        var result: Result<SSAPIConfirm2FAResponse, SSAPIAuthConfirm2FAError>!
        
        let semaphore = DispatchSemaphore(value: 0)
        
        URLSession.shared.uploadTask(with: request, from: jsonData) { (data, response, error) in
            
            if error != nil || data == nil {
                result = .failure(.serverError)
                semaphore.signal()
                return
            }

            guard let response = response as? HTTPURLResponse else {
                result = .failure(.serverError)
                semaphore.signal()
                return
            }
            
            guard response.statusCode == 200 else {
                if response.statusCode == 400 {
                    result = .failure(.invalidCode)
                } else if response.statusCode == 401 {
                    self.notificationCentre.post(name: .communicationController_Unauthorised, object: nil)
                    result = .failure(.unauthorised)
                } else if response.statusCode == 403 {
                    // A 403 response probably means the mfaMethodName was unrecognised
                    result = .failure(.possibleIncorrectMFAMethodName)
                } else if response.statusCode == 429 {
                    result = .failure(.requestThrottled)
                } else {
                    result = .failure(.serverError)
                }
                semaphore.signal()
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let decodedLoginResponse = try decoder.decode(SSAPIConfirm2FAResponse.self, from: data!)
                result = .success(decodedLoginResponse)
            } catch {
                result = .failure(.badResponseFromServer)
            }
            
            semaphore.signal()
            
        }.resume()
        
        if semaphore.wait(timeout: timeoutDuration) == .timedOut {
            result = .failure(.timeout)
        }
        
        return result
        
    }
    
    public func deactivateTwoFactorAuthentication(authToken: String, mfaMethodName: String, confirm2FACode: String, serverAddress: String) -> Result<Void, SSAPIAuthDeactivate2FAError> {
        
        let path = "\(serverAddress)/v1/auth/\(mfaMethodName)/deactivate/"
        guard let url = URL(string: path) else {
            return .failure(.invalidUrl)
        }
        
        guard let confirm2FACodeInt = Int(confirm2FACode) else {
            return .failure(.badFormat)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Token \(authToken)", forHTTPHeaderField: "Authorization")
        let json = [
            "code": confirm2FACodeInt
        ]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: json, options: []) else {
            return .failure(.badFormat)
        }
        
        var result: Result<Void, SSAPIAuthDeactivate2FAError>!
        
        let semaphore = DispatchSemaphore(value: 0)
        
        URLSession.shared.uploadTask(with: request, from: jsonData) { (data, response, error) in
            
            if error != nil || data == nil {
                result = .failure(.serverError)
                semaphore.signal()
                return
            }

            guard let response = response as? HTTPURLResponse else {
                result = .failure(.serverError)
                semaphore.signal()
                return
            }
            
            guard response.statusCode == 204 else {
                if response.statusCode == 400 {
                    result = .failure(.invalidCode)
                } else if response.statusCode == 401 {
                    self.notificationCentre.post(name: .communicationController_Unauthorised, object: nil)
                    result = .failure(.unauthorised)
                } else if response.statusCode == 403 {
                    // A 403 response probably means the mfaMethodName was unrecognised
                    result = .failure(.possibleIncorrectMFAMethodName)
                } else if response.statusCode == 429 {
                    result = .failure(.requestThrottled)
                } else {
                    result = .failure(.serverError)
                }
                semaphore.signal()
                return
            }
            
            // (()) is a way to pass Void to success
            result = .success(())
            
            semaphore.signal()
            
        }.resume()
        
        if semaphore.wait(timeout: timeoutDuration) == .timedOut {
            result = .failure(.timeout)
        }
        
        return result
        
    }
    
    public func logOut(authToken: String, serverAddress: String) -> Result<Void, SSAPIAuthLogOutError> {
        
        let path = "\(serverAddress)/v1/auth/logout/"
        guard let url = URL(string: path) else {
            return .failure(.invalidUrl)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Token \(authToken)", forHTTPHeaderField: "Authorization")
        let json: [String: Any] = [:]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: json, options: []) else {
            return .failure(.badFormat)
        }
        
        var result: Result<Void, SSAPIAuthLogOutError>!
        
        let semaphore = DispatchSemaphore(value: 0)
        
        URLSession.shared.uploadTask(with: request, from: jsonData) { (data, response, error) in
            
            if error != nil || data == nil {
                result = .failure(.serverError)
                semaphore.signal()
                return
            }

            guard let response = response as? HTTPURLResponse else {
                result = .failure(.serverError)
                semaphore.signal()
                return
            }
            
            guard response.statusCode == 204 else {
                if response.statusCode == 401 {
                    self.notificationCentre.post(name: .communicationController_Unauthorised, object: nil)
                    result = .failure(.unauthorised)
                } else if response.statusCode == 429 {
                    result = .failure(.requestThrottled)
                } else {
                    result = .failure(.serverError)
                }
                semaphore.signal()
                return
            }
            
            // (()) is a way to pass Void to success
            result = .success(())
            
            semaphore.signal()
            
        }.resume()
        
        if semaphore.wait(timeout: timeoutDuration) == .timedOut {
            result = .failure(.timeout)
        }
        
        return result
        
    }
    
    public func deleteUserAccount(currentPassword: String, authToken: String, serverAddress: String) -> Result<Void, SSAPIAuthDeleteUserAccountError> {
        
        let path = "\(serverAddress)/v1/auth/users/me/"
        guard let url = URL(string: path) else {
            return .failure(.invalidUrl)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Token \(authToken)", forHTTPHeaderField: "Authorization")
        let json = [
            "current_password": currentPassword
        ]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: json, options: []) else {
            return .failure(.badFormat)
        }
        
        var result: Result<Void, SSAPIAuthDeleteUserAccountError>!
        
        let semaphore = DispatchSemaphore(value: 0)
        
        URLSession.shared.uploadTask(with: request, from: jsonData) { (data, response, error) in
            
            if error != nil || data == nil {
                result = .failure(.serverError)
                semaphore.signal()
                return
            }

            guard let response = response as? HTTPURLResponse else {
                result = .failure(.serverError)
                semaphore.signal()
                return
            }
            
            guard response.statusCode == 204 else {
                if response.statusCode == 400 {
                    result = .failure(.invalidPassword)
                } else if response.statusCode == 401 {
                    self.notificationCentre.post(name: .communicationController_Unauthorised, object: nil)
                    result = .failure(.unauthorised)
                } else if response.statusCode == 429 {
                    result = .failure(.requestThrottled)
                } else {
                    result = .failure(.serverError)
                }
                semaphore.signal()
                return
            }
            
            // (()) is a way to pass Void to success
            result = .success(())
            
            semaphore.signal()
            
        }.resume()
        
        if semaphore.wait(timeout: timeoutDuration) == .timedOut {
            result = .failure(.timeout)
        }
        
        return result
        
    }
    
}
