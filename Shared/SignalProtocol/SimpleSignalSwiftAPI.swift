//
//  SimpleSignalSwiftAPI.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 17/12/2020.
//

import Foundation

//https://michaellong.medium.com/how-to-chain-api-calls-using-swift-5s-new-result-type-and-gcd-56025b51033c

public enum SimplesSignalSwiftAPIError: Error {
    case url, json, server
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
            return .failure(.json)
        }
        
        var result: Result<SimpleSignalSwiftAPILoginResponse, SimplesSignalSwiftAPIError>!
        
        let semaphore = DispatchSemaphore(value: 0)
        
        URLSession.shared.uploadTask(with: request, from: jsonData) { (data, response, error) in
            
            if error != nil || data == nil {
                print("Client error!")
                result = .failure(.server)
                return
            }

            guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
                print("Server error!")
                result = .failure(.server)
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let decodedLoginResponse = try decoder.decode(SimpleSignalSwiftAPILoginResponse.self, from: data!)
                result = .success(decodedLoginResponse)
            } catch {
                print("JSON error: \(error.localizedDescription)")
                result = .failure(.json)
            }
            
            semaphore.signal()
            
        }.resume()
        
        _ = semaphore.wait(wallTimeout: .distantFuture)
        
        return result
        
    }
    
}
