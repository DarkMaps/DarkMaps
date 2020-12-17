//
//  SimpleSignalSwiftAPI.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 17/12/2020.
//

import Foundation

//https://michaellong.medium.com/how-to-chain-api-calls-using-swift-5s-new-result-type-and-gcd-56025b51033c

public enum SimplesSignalSwiftAPIError: Error {
    case url, clientJson, serverJson, serverError, server(String), needsTwoFactorAuthentication(String), requestThrottled
}

public struct SimpleSignalSwiftAPILoginResponse: Codable {
    
    var authToken: String
    
    init(authToken: String) {
        self.authToken = authToken
    }
    
}

public class SimpleSignalSwiftAPI {
    
    public func login(username: String, password: String, serverAddress: String) -> Result<SimpleSignalSwiftAPILoginResponse, SimplesSignalSwiftAPIError> {
        
        let path = "\(serverAddress)/v1/auth/login/"
        guard let url = URL(string: path) else {
            return .failure(.url)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let json = [
            "email": username,
            "password": password
        ]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: json, options: []) else {
            return .failure(.clientJson)
        }
        
        var result: Result<SimpleSignalSwiftAPILoginResponse, SimplesSignalSwiftAPIError>!
        
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
                            result = .failure(.server(nonFieldErrors.first ?? "An error occured"))
                        } else {
                            result = .failure(.server("Incorrect data passed to server"))
                        }
                    } catch {
                        result = .failure(.serverJson)
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
                let decodedLoginResponse = try decoder.decode(SimpleSignalSwiftAPILoginResponse.self, from: data!)
                result = .success(decodedLoginResponse)
            } catch {
                do {
                    // 200 responses are stil returned when 2FA is required
                    // Here we parse the data returned to find the ephemeral token and return it
                    let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
                    if let ephemeralToken = (json?["ephemeral_token"] as? String) {
                        result = .failure(.needsTwoFactorAuthentication(ephemeralToken))
                    } else {
                        result = .failure(.server("Incorrect data passed to server"))
                    }
                } catch {
                    result = .failure(.serverJson)
                }
            }
            
            semaphore.signal()
            
        }.resume()
        
        _ = semaphore.wait(wallTimeout: .distantFuture)
        
        return result
        
    }
    
}