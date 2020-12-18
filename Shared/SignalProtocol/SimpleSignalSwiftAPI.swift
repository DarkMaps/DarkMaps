//
//  SimpleSignalSwiftAPI.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 17/12/2020.
//

import Foundation

//https://michaellong.medium.com/how-to-chain-api-calls-using-swift-5s-new-result-type-and-gcd-56025b51033c

public class SimpleSignalSwiftAPI {
    
    public func login(username: String, password: String, serverAddress: String) -> Result<SSAPILoginResponse, SSAPILoginError> {
        
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
        
        var result: Result<SSAPILoginResponse, SSAPILoginError>!
        
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
        
        _ = semaphore.wait(wallTimeout: .distantFuture)
        
        return result
        
    }
    
    public func submitTwoFactorAuthentication(ephemeralToken: String, submit2FACode: String, serverAddress: String) -> Result<SSAPISubmit2FAResponse, SSAPISubmit2FAError> {
        
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
        
        var result: Result<SSAPISubmit2FAResponse, SSAPISubmit2FAError>!
        
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
        
        _ = semaphore.wait(wallTimeout: .distantFuture)
        
        return result
        
    }
    
    public func activateTwoFactorAuthentication(authToken: String, mfaMethodName: String, serverAddress: String) -> Result<SSAPIActivate2FAResponse, SSAPIActivate2FAError> {
        
        let path = "\(serverAddress)/v1/auth/\(mfaMethodName)/activate/"
        guard let url = URL(string: path) else {
            return .failure(.invalidUrl)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(authToken, forHTTPHeaderField: "Authorization")
        let json: [String: Any] = [:]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: json, options: []) else {
            return .failure(.badFormat)
        }
        
        var result: Result<SSAPIActivate2FAResponse, SSAPIActivate2FAError>!
        
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
                if response.statusCode == 403 {
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
        
        _ = semaphore.wait(wallTimeout: .distantFuture)
        
        return result
        
    }
    
    public func confirmTwoFactorAuthentication(authToken: String, mfaMethodName: String, confirm2FACode: String, serverAddress: String) -> Result<SSAPIConfirm2FAResponse, SSAPIConfirm2FAError> {
        
        let path = "\(serverAddress)/v1/auth/\(mfaMethodName)/confirm/"
        guard let url = URL(string: path) else {
            return .failure(.invalidUrl)
        }
        
        guard let confirm2FACodeInt = Int(confirm2FACode) else {
            return .failure(.badFormat)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(authToken, forHTTPHeaderField: "Authorization")
        let json = [
            "code": confirm2FACodeInt
        ]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: json, options: []) else {
            return .failure(.badFormat)
        }
        
        var result: Result<SSAPIConfirm2FAResponse, SSAPIConfirm2FAError>!
        
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
                    result = .failure(.invalidAuthorisation)
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
        
        _ = semaphore.wait(wallTimeout: .distantFuture)
        
        return result
        
    }
    
    public func deactivateTwoFactorAuthentication(authToken: String, mfaMethodName: String, confirm2FACode: String, serverAddress: String) -> Result<Void, SSAPIDeactivate2FAError> {
        
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
        request.setValue(authToken, forHTTPHeaderField: "Authorization")
        let json = [
            "code": confirm2FACodeInt
        ]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: json, options: []) else {
            return .failure(.badFormat)
        }
        
        var result: Result<Void, SSAPIDeactivate2FAError>!
        
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
                    result = .failure(.invalidAuthorisation)
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
        
        _ = semaphore.wait(wallTimeout: .distantFuture)
        
        return result
        
    }
    
    public func logOut(authToken: String, serverAddress: String) -> Result<Void, SSAPILogOutError> {
        
        let path = "\(serverAddress)/v1/auth/logout/"
        guard let url = URL(string: path) else {
            return .failure(.invalidUrl)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(authToken, forHTTPHeaderField: "Authorization")
        let json: [String: Any] = [:]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: json, options: []) else {
            return .failure(.badFormat)
        }
        
        var result: Result<Void, SSAPILogOutError>!
        
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
                    result = .failure(.invalidAuthorisation)
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
        
        _ = semaphore.wait(wallTimeout: .distantFuture)
        
        return result
        
    }
    
    public func deleteUserAccount(currentPassword: String, authToken: String, serverAddress: String) -> Result<Void, SSAPIDeleteUserAccountError> {
        
        let path = "\(serverAddress)/v1/auth/users/me/"
        guard let url = URL(string: path) else {
            return .failure(.invalidUrl)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(authToken, forHTTPHeaderField: "Authorization")
        let json = [
            "currentPassword": currentPassword
        ]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: json, options: []) else {
            return .failure(.badFormat)
        }
        
        var result: Result<Void, SSAPIDeleteUserAccountError>!
        
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
                    result = .failure(.invalidAuthorisation)
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
        
        _ = semaphore.wait(wallTimeout: .distantFuture)
        
        return result
        
    }
    
}
