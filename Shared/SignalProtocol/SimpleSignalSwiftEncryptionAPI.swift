//
//  SimpleSignalSwiftEncryptionAPI.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 19/12/2020.
//

import Foundation

//https://michaellong.medium.com/how-to-chain-api-calls-using-swift-5s-new-result-type-and-gcd-56025b51033c

public class SimpleSignalSwiftEncryptionAPI {
    
    let address: ProtocolAddress
    private let keychainSwift: KeychainSwift
    private var store: KeychainSignalProtocolStore? = nil
    
    private var timeoutDuration: DispatchTime {
        return .now() + 5
    }
    
    
    #if DEBUG
    //Required for testing
    public func exposePrivateStore() -> KeychainSignalProtocolStore? {
        return self.store
    }
    #endif
    
    
    init(address: ProtocolAddress) throws {
        self.address = address
        self.keychainSwift = KeychainSwift(keyPrefix: address.combinedValue)
        self.store = try? KeychainSignalProtocolStore(keychainSwift: keychainSwift)
    }
    
    public func deviceExists(authToken: String, serverAddress: String) -> Bool {
        guard let store = self.store else { return false }
        // If a device exists locally need to check it matches server
        let getDeviceOutcome = self.getDevice(authToken: authToken, serverAddress: serverAddress)
        switch getDeviceOutcome {
        case .failure:
            let _ = self.deleteDevice(authToken: authToken, serverAddress: serverAddress)
            return false
        case .success(let deviceDetails):
            let localRegistrationId = try? store.localRegistrationId(context: nil)
            if deviceDetails.registrationId == (localRegistrationId ?? UInt32(0)) {
                return true
            } else {
                let _ = self.deleteDevice(authToken: authToken, serverAddress: serverAddress)
                return false
            }
        }
    }
    
    public var registrationId: Int? {
        guard let store = self.store else {
            return nil
        }
        guard let uInt32RegistrationId = try? store.localRegistrationId(context: nil) else {
            return nil
        }
        return Int(uInt32RegistrationId)
    }
    
    public func createDevice(authToken: String, serverAddress: String) -> Result <Int, SSAPIEncryptionError> {
            
        do {
            let identityKey = try IdentityKeyPair.generate()
            let registrationId = UInt32(Int.random(in: 1..<10000))
            
            let store = try KeychainSignalProtocolStore.init(keychainSwift: keychainSwift, address: address, identity: identityKey, registrationId: registrationId)
            
            var allPreKeys: [PreKeyRecord] = []
            for i in 1...50 {
                let preKey = try PreKeyRecord.init(id: UInt32(i), privateKey: try PrivateKey.generate())
                allPreKeys.append(preKey)
                try store.storePreKey(
                    preKey,
                    id: UInt32(i),
                    context: nil)
            }
            
            
            let signedPreKey = try PrivateKey.generate()
            let signedPrekeySignature = try identityKey.privateKey.generateSignature(
                message: signedPreKey.publicKey().serialize()
            )
            let signedPreKeyRecord = try SignedPreKeyRecord.init(
                id: 1,
                timestamp: Date().ticks,
                privateKey: signedPreKey,
                signature: signedPrekeySignature)
            try store.storeSignedPreKey(signedPreKeyRecord, id: 1, context: nil)
            
            let result = uploadDevice(
                serverAddress: serverAddress,
                authToken: authToken,
                deviceAddress: address.combinedValue,
                identityKey: identityKey.identityKey,
                registrationId: registrationId,
                preKeys: allPreKeys,
                signedPreKey: signedPreKeyRecord)
            
            switch result {
            case .success:
                self.store = store
                return .success(Int(registrationId))
            case .failure(let error):
                return .failure(error)
            }
            
        } catch {
            print(error)
            print("Error creating keys")
            return .failure(.badFormat)
        }
    }
    
    private func uploadDevice(serverAddress: String, authToken: String, deviceAddress: String, identityKey: IdentityKey, registrationId: UInt32, preKeys: [PreKeyRecord], signedPreKey: SignedPreKeyRecord) -> Result<Void, SSAPIEncryptionError> {
        
        let path = "\(serverAddress)/v1/devices/"
        guard let url = URL(string: path) else {
            return .failure(.invalidUrl)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Token \(authToken)", forHTTPHeaderField: "Authorization")
        let json: [String: Any]
        do {
            json = [
                "address": deviceAddress,
                "identity_key": (try identityKey.serialize()).toBase64String(),
                "registration_id": registrationId,
                "pre_keys": try preKeys.map({ preKey in
                    return [
                        "key_id": try preKey.id(),
                        "public_key": (try preKey.publicKey().serialize()).toBase64String()
                    ]
                }),
                "signed_pre_key": [
                    "key_id": try signedPreKey.id(),
                    "public_key": (try signedPreKey.publicKey().serialize()).toBase64String(),
                    "signature": (try signedPreKey.signature()).toBase64String()
                ]
            ]
        } catch {
            print("Error creating JSON object")
            return .failure(.badFormat)
        }
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: json, options: []) else {
            print("Error creating JSON data")
            return .failure(.badFormat)
        }
        
        var result: Result<Void, SSAPIEncryptionError>!
        
        let semaphore = DispatchSemaphore(value: 0)
        
        URLSession.shared.uploadTask(with: request, from: jsonData) { (data, response, error) in
            
            let processedResponse = self.handleURLErrors(successCode: 201, data: data, response: response, error: error)
            
            print(processedResponse)
            
            switch processedResponse {
            case .success:
                result = .success(())
            case .failure(let error):
                result = .failure(error)
            }
            
            semaphore.signal()
            
        }.resume()
        
        if semaphore.wait(timeout: timeoutDuration) == .timedOut {
            result = .failure(.timeout)
        }
        
        return result
        
    }
    
    public func sendMessage(message: String, recipientName: String, recipientDeviceId: UInt32, authToken: String, serverAddress: String) -> Result<Void, SSAPIEncryptionError> {
        
        guard let store = self.store else {
            return(.failure(.noStore))
        }
        
        do {
            
            let recipientAddress = try ProtocolAddress(name: recipientName, deviceId: recipientDeviceId)
            
            if let session = try? store.loadSession(for: recipientAddress, context: nil) {
                print("Session exists: Sending message")
                return (sendMessageUsingStore(message: message, recipientAddress: recipientAddress, recipientRegistrationId: Int(try session.remoteRegistrationId()), authToken: authToken, serverAddress: serverAddress))
            } else {
                print("No session: Obtaining preKeyBundle")
                let registrationId = try store.localRegistrationId(context: nil)
                let preKeyBundleResult = obtainPreKeyBundle(recipient: recipientAddress, sendersRegistrationId: Int(registrationId), authToken: authToken, serverAddress: serverAddress)
                switch preKeyBundleResult {
                case .success(let preKeyBundle):
                    try processPreKeyBundle(
                        preKeyBundle,
                        for: recipientAddress,
                        sessionStore: store,
                        identityStore: store,
                        context: nil)
                    return (sendMessageUsingStore(message: message, recipientAddress: recipientAddress, recipientRegistrationId: Int(try preKeyBundle.registrationId()), authToken: authToken, serverAddress: serverAddress))
                case .failure(let error):
                    return(.failure(error))
                }
            }
            
        } catch {
            return(.failure(.badFormat))
        }
        
    }
    
    private func sendMessageUsingStore(message: String, recipientAddress: ProtocolAddress, recipientRegistrationId: Int, authToken: String, serverAddress: String) -> Result<Void, SSAPIEncryptionError> {
        
        guard let store = self.store else {
            return(.failure(.noStore))
        }
        
        guard let messageData = message.data(using: .utf8) else {
            return(.failure(.badFormat))
        }
        
        do {
            let cipherText = try signalEncrypt(
                message: messageData,
                for: recipientAddress,
                sessionStore: store,
                identityStore: store,
                context: nil)
            
            
            var messageData: String
            if try cipherText.messageType() == .preKey {
                print("Creating prekey message")
                messageData = (try PreKeySignalMessage(bytes: try cipherText.serialize()).serialize()).toBase64String()
            } else if try cipherText.messageType() == .whisper {
                print("Creating standard message")
                messageData = (try SignalMessage(bytes: try cipherText.serialize()).serialize()).toBase64String()
            } else {
                return(.failure(.badFormat))
            }
            
            guard let registrationId = try? store.localRegistrationId(context: nil) else {
                return(.failure(.senderHasNoRegisteredDevice))
            }
            
            let path = "\(serverAddress)/v1/\(registrationId)/messages/"
            guard let url = URL(string: path) else {
                return .failure(.invalidUrl)
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Token \(authToken)", forHTTPHeaderField: "Authorization")
            let messageJsonObject = [
                "registration_id": recipientRegistrationId,
                "content": messageData
            ] as [String : Any]
            guard let messageJsonData = try? JSONSerialization.data(withJSONObject: messageJsonObject, options: []) else {
                return .failure(.badFormat)
            }
            guard let messageJsonString = String(data: messageJsonData, encoding: .utf8) else {
                return .failure(.badFormat)
            }
            let bodyJson = [
                "recipient": recipientAddress.name,
                "message": messageJsonString
            ]
            guard let bodyJsonData = try? JSONSerialization.data(withJSONObject: bodyJson, options: []) else {
                return .failure(.badFormat)
            }
            
            
            var result: Result<Void, SSAPIEncryptionError>!
            
            let semaphore = DispatchSemaphore(value: 0)
            
            URLSession.shared.uploadTask(with: request, from: bodyJsonData) { (data, response, error) in
                
                let processedResponse = self.handleURLErrors(successCode: 201, data: data, response: response, error: error)
                
                switch processedResponse {
                case .success:
                    result = .success(())
                case .failure(let error):
                    result = .failure(error)
                }
                
                semaphore.signal()
                
            }.resume()
            
            if semaphore.wait(timeout: timeoutDuration) == .timedOut {
                result = .failure(.timeout)
            }
            
            return result
        } catch {
            print(error)
            return(.failure(.badFormat))
        }
    }
    
    private func obtainPreKeyBundle(recipient: ProtocolAddress, sendersRegistrationId: Int, authToken: String, serverAddress: String) -> Result<PreKeyBundle, SSAPIEncryptionError> {
        let recipientData = Data(recipient.combinedValue.utf8)
        let recipientHex = recipientData.map{ String(format:"%02x", $0) }.joined()
        let path = "\(serverAddress)/v1/prekeybundles/\(recipientHex)/\(sendersRegistrationId)/"
        guard let url = URL(string: path) else {
            return .failure(.invalidUrl)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Token \(authToken)", forHTTPHeaderField: "Authorization")
        
        var result: Result<PreKeyBundle, SSAPIEncryptionError>!
        
        let semaphore = DispatchSemaphore(value: 0)
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            let processedResponse = self.handleURLErrors(successCode: 200, data: data, response: response, error: error)
            
            switch processedResponse {
            case .failure(let error):
                result = .failure(error)
            case .success:
                
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    let decodedResponse = try decoder.decode(SSAPIPreKeyBundleResponse.self, from: data!)
                    guard let deviceIdString = decodedResponse.address.split(separator: ".").last else {
                        print("Error decoding address")
                        result = .failure(.badFormat)
                        return
                    }
                    guard let deviceId = UInt32(deviceIdString) else {
                        print("Error decoding address")
                        result = .failure(.badFormat)
                        return
                    }
                    guard let preKeyArray: [UInt8] = decodedResponse.preKey.publicKey.toUint8Array() else {
                        print("Error decoding publicKey")
                        result = .failure(.badFormat)
                        return
                    }
                    guard let signedPreKeyArray: [UInt8] = decodedResponse.signedPreKey.publicKey.toUint8Array() else {
                        print("Error decoding signedPreKey")
                        result = .failure(.badFormat)
                        return
                    }
                    guard let signatureArray: [UInt8] = decodedResponse.signedPreKey.signature.toUint8Array() else {
                        print("Error decoding signature")
                        result = .failure(.badFormat)
                        return
                    }
                    guard let identityArray: [UInt8] = decodedResponse.identityKey.toUint8Array() else {
                        print("Error decoding identityKey")
                        result = .failure(.badFormat)
                        return
                    }
                    let preKeyBundle = try PreKeyBundle(
                        registrationId: decodedResponse.registrationId,
                        deviceId: deviceId,
                        prekeyId: decodedResponse.preKey.keyId,
                        prekey: PublicKey(preKeyArray),
                        signedPrekeyId: decodedResponse.signedPreKey.keyId,
                        signedPrekey: PublicKey(signedPreKeyArray),
                        signedPrekeySignature: signatureArray,
                        identity: IdentityKey(bytes: identityArray))
                    result = .success(preKeyBundle)
                } catch {
                    print("Error creating pre key bundle")
                    print(error)
                    let responseString = String(data: data!, encoding: .utf8)
                    print("raw response: \(responseString ?? "Not Decipherable")")
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
    
    public func getMessages(authToken: String, serverAddress: String) -> Result<[SSAPIGetMessagesOutput], SSAPIEncryptionError> {
        
        guard let store = self.store else {
            return(.failure(.noStore))
        }
        
        guard let recipientRegistrationId = try? store.localRegistrationId(context: nil) else {
            return(.failure(.userHasNoRegisteredDevice))
        }
        
        let path = "\(serverAddress)/v1/\(recipientRegistrationId)/messages/"
        guard let url = URL(string: path) else {
            return .failure(.invalidUrl)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Token \(authToken)", forHTTPHeaderField: "Authorization")
        
        var result: Result<[SSAPIGetMessagesOutput], SSAPIEncryptionError>!
        
        let semaphore = DispatchSemaphore(value: 0)
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            let processedResponse = self.handleURLErrors(successCode: 200, data: data, response: response, error: error)
            
            switch processedResponse {
            case .failure(let error):
                result = .failure(error)
            case .success:
                
                do {
                    var output: [SSAPIGetMessagesOutput] = []
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    let decodedResponse = try decoder.decode([SSAPIGetMessagesResponse].self, from: data!)
                    for input in decodedResponse {
                        output.append(try self.decryptMessage(input: input))
                    }
                    result = .success(output)
                } catch {
                    print(error)
                    print("error decrypting messages")
                    let responseString = String(data: data!, encoding: .utf8)
                    print("raw response: \(responseString ?? "Not decipherable")")
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
    
    private func decryptMessage(input: SSAPIGetMessagesResponse) throws -> SSAPIGetMessagesOutput {
        
        guard let store = self.store else {
            throw SSAPIEncryptionError.noStore
        }
        
        let address: ProtocolAddress
        do {
            address = try ProtocolAddress(input.senderAddress)
        } catch {
            throw SSAPIEncryptionError.invalidSenderAddress
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let messageContentData = input.content.data(using: .utf8) else {
            return(SSAPIGetMessagesOutput(id: input.id, error: .badResponseFromServer, senderAddress: address))
        }
        guard let messageContent = try? decoder.decode(SSAPIGetMessagesContent.self, from: messageContentData) else {
            print("Unable to create SSAPIGetMessagesContent from string")
            return(SSAPIGetMessagesOutput(id: input.id, error: .badResponseFromServer, senderAddress: address))
        }
        
        let decryptedMessageString: String
        guard let contentArray = messageContent.content.toUint8Array() else {
            print("Unable to convert content array to Uint8Array")
            return(SSAPIGetMessagesOutput(id: input.id, error: .badResponseFromServer, senderAddress: address))
        }
        
        do {
            let decryptedMessageData = try signalDecrypt(
                message: SignalMessage(bytes: contentArray),
                from: address,
                sessionStore: store,
                identityStore: store,
                context: nil)

            decryptedMessageString = String(decoding: decryptedMessageData, as: UTF8.self)
        } catch SignalError.untrustedIdentity {
            
            return(SSAPIGetMessagesOutput(id: input.id, error: .alteredIdentity, senderAddress: address))
        } catch {
            do {
                let decryptedMessageData = try signalDecryptPreKey(
                    message: PreKeySignalMessage(bytes: contentArray),
                    from: address,
                    sessionStore: store,
                    identityStore: store,
                    preKeyStore: store,
                    signedPreKeyStore: store,
                    context: nil)
                decryptedMessageString = String(decoding: decryptedMessageData, as: UTF8.self)
            } catch SignalError.untrustedIdentity {
                return(SSAPIGetMessagesOutput(id: input.id, error: .alteredIdentity, senderAddress: address))
            } catch {
                return(SSAPIGetMessagesOutput(id: input.id, error: .unableToDecrypt, senderAddress: address))
            }
        }
        let output = SSAPIGetMessagesOutput(id: input.id, message: decryptedMessageString, senderAddress: address)
        return(output)
        
    }
    
    public func getDevice(authToken: String, serverAddress: String) -> Result<SSAPIGetDeviceOutput, SSAPIEncryptionError> {
        
        let path = "\(serverAddress)/v1/devices/"
        guard let url = URL(string: path) else {
            return .failure(.invalidUrl)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Token \(authToken)", forHTTPHeaderField: "Authorization")
        
        var result: Result<SSAPIGetDeviceOutput, SSAPIEncryptionError>!
        
        let semaphore = DispatchSemaphore(value: 0)
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            let processedResponse = self.handleURLErrors(successCode: 200, data: data, response: response, error: error)
            
            switch processedResponse {
            case .failure(let error):
                result = .failure(error)
            case .success:
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    let decodedResponse = try decoder.decode(SSAPIGetDeviceOutput.self, from: data!)
                    result = .success(decodedResponse)
                } catch {
                    print(error)
                    print("error decoding device")
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
    
    public func deleteDevice(authToken: String, serverAddress: String) -> Result<Void, SSAPIEncryptionError> {
        
        let path = "\(serverAddress)/v1/devices/"
        guard let url = URL(string: path) else {
            return .failure(.invalidUrl)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Token \(authToken)", forHTTPHeaderField: "Authorization")
        
        var result: Result<Void, SSAPIEncryptionError>!
        
        let semaphore = DispatchSemaphore(value: 0)
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            let processedResponse = self.handleURLErrors(successCode: 204, data: data, response: response, error: error)
            
            switch processedResponse {
            case .failure(let error):
                result = .failure(error)
                // Clear data anyway
                self.deleteLocalDeviceDetails()
            case .success:
                result = .success(())
                // Store may be empty as we are a new user deleting an old device
                self.deleteLocalDeviceDetails()
            }
            
            semaphore.signal()
            
        }.resume()
        
        if semaphore.wait(timeout: timeoutDuration) == .timedOut {
            result = .failure(.timeout)
        }
        
        return result
    }
    
    public func deleteLocalDeviceDetails() {
        print("Clearing data")
        if let store = self.store {
            store.clearAllData()
            self.store = nil
        }
    }
    
    public func deleteMessage(authToken: String, serverAddress: String, messageIds: [Int]) -> Result<[Int: SSAPIDeleteMessageOutcome], SSAPIEncryptionError> {
        
        guard let store = self.store else {
            return(.failure(.noStore))
        }
        
        guard let localRegistrationId = try? store.localRegistrationId(context: nil) else {
            return(.failure(.userHasNoRegisteredDevice))
        }
        
        let path = "\(serverAddress)/v1/\(localRegistrationId)/messages/"
        guard let url = URL(string: path) else {
            return .failure(.invalidUrl)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Token \(authToken)", forHTTPHeaderField: "Authorization")
        guard let jsonData = try? JSONSerialization.data(withJSONObject: messageIds, options: []) else {
            return .failure(.badFormat)
        }
        
        var result: Result<[Int: SSAPIDeleteMessageOutcome], SSAPIEncryptionError>!
        
        let semaphore = DispatchSemaphore(value: 0)
        
        URLSession.shared.uploadTask(with: request, from: jsonData) { (data, response, error) in
            
            let processedResponse = self.handleURLErrors(successCode: 200, data: data, response: response, error: error)
            
            print(processedResponse)
            
            switch processedResponse {
            case .failure(let error):
                result = .failure(error)
            case .success:
                do {
                    var output: [Int: SSAPIDeleteMessageOutcome] = [:]
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    let decodedResponse = try decoder.decode([String].self, from: data!)
                    print("decoded response successfully")
                    for (index, outcomeCode) in decodedResponse.enumerated() {
                        guard let messageId = messageIds[safe: index] else {
                            throw SSAPIEncryptionError.badResponseFromServer
                        }
                        if outcomeCode == "message_deleted" {
                            output[messageId] = .messageDeleted
                        } else if outcomeCode == "not_message_owner" {
                            output[messageId] = .notMessageOwner
                        } else if outcomeCode == "non-existant_message" {
                            output[messageId] = .nonExistantMessage
                        } else {
                            output[messageId] = .serverError
                        }
                    }
                    result = .success(output)
                } catch {
                    print("Error decoding response")
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
    
    public func updatePreKeys(authToken: String, serverAddress: String) -> Result<Void, SSAPIEncryptionError> {
        
        guard let store = self.store else {
            return(.failure(.noStore))
        }
        
        guard let userRegistrationId = try? store.localRegistrationId(context: nil) else {
            return(.failure(.userHasNoRegisteredDevice))
        }
        
        guard let (preKeyCount, maxKeyId) = try? store.countPreKeys() else {
            return(.failure(.unableToGetPreKeyStatus))
        }
        
        let numberOfPreKeysRequired = 50 - preKeyCount
        
        if numberOfPreKeysRequired < 1 {
            return(.success(()))
        }
        
        var allPreKeys: [PreKeyRecord] = []
        do {
            for i in (maxKeyId + 1)...(maxKeyId + 1 + numberOfPreKeysRequired) {
                let preKey = try PreKeyRecord.init(id: UInt32(i), privateKey: try PrivateKey.generate())
                allPreKeys.append(preKey)
                try store.storePreKey(
                    preKey,
                    id: UInt32(i),
                    context: nil)
            }
        } catch {
            return(.failure(.unableToCreateKeys))
        }
        
        
        let path = "\(serverAddress)/v1/\(userRegistrationId)/prekeys/"
        guard let url = URL(string: path) else {
            return .failure(.invalidUrl)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Token \(authToken)", forHTTPHeaderField: "Authorization")
        var json: [[String: Any]] = []
        do {
            for preKey in allPreKeys {
                json.append([
                    "key_id": try preKey.id(),
                    "public_key": (try preKey.publicKey().serialize()).toBase64String()
                ])
            }
        } catch {
            return .failure(.badFormat)
        }
        
        print(json)
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: json, options: []) else {
            return .failure(.badFormat)
        }
        
        
        var result: Result<Void, SSAPIEncryptionError>!
        
        let semaphore = DispatchSemaphore(value: 0)
        
        URLSession.shared.uploadTask(with: request, from: jsonData) { (data, response, error) in
            
            let processedResponse = self.handleURLErrors(successCode: 200, data: data, response: response, error: error)
            
            switch processedResponse {
            case .failure(let error):
                result = .failure(error)
            case .success:
                result = .success(())
            }
            
            semaphore.signal()
            
        }.resume()
        
        if semaphore.wait(timeout: timeoutDuration) == .timedOut {
            result = .failure(.timeout)
        }
        
        return result
        
    }
    
    public func updateSignedPreKey(authToken: String, serverAddress: String) -> Result<Void, SSAPIEncryptionError> {
        
        guard let store = self.store else {
            return(.failure(.noStore))
        }
        
        guard let userRegistrationId = try? store.localRegistrationId(context: nil) else {
            return(.failure(.userHasNoRegisteredDevice))
        }
        
        guard let (spkAge, maxKeyId) = try? store.signedPreKeyAge() else {
            return(.failure(.unableToGetPreKeyStatus))
        }
        
        //60,000,000 = 1min, 432000000000 = 5days
        let spkHasExpired = spkAge > 432000000000
        print("Expired: \(spkHasExpired)")
        
        if !spkHasExpired {
            return(.success(()))
        }
        
        guard let identityKey = try? store.identityKeyPair(context: nil) else {
            return(.failure(.userHasNoRegisteredDevice))
        }
        
        let signedPreKeyRecord: SignedPreKeyRecord
        do {
            let signedPreKey = try PrivateKey.generate()
            let signedPrekeySignature = try identityKey.privateKey.generateSignature(
                message: signedPreKey.publicKey().serialize()
            )
            signedPreKeyRecord = try SignedPreKeyRecord.init(
                id: UInt32(maxKeyId + 1),
                timestamp: Date().ticks,
                privateKey: signedPreKey,
                signature: signedPrekeySignature)
            try store.storeSignedPreKey(signedPreKeyRecord, id: 1, context: nil)
        } catch {
            return(.failure(.unableToCreateKeys))
        }
        
        
        let path = "\(serverAddress)/v1/\(userRegistrationId)/signedprekeys/"
        guard let url = URL(string: path) else {
            return .failure(.invalidUrl)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Token \(authToken)", forHTTPHeaderField: "Authorization")
        let json: [String: Any]
        do {
            json = [
                "key_id": try signedPreKeyRecord.id(),
                "public_key": (try signedPreKeyRecord.publicKey().serialize()).toBase64String(),
                "signature": (try signedPreKeyRecord.signature()).toBase64String()
            ]
        } catch {
            return(.failure(.badFormat))
        }
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: json, options: []) else {
            return .failure(.badFormat)
        }
        
        var result: Result<Void, SSAPIEncryptionError>!
        
        let semaphore = DispatchSemaphore(value: 0)
        
        URLSession.shared.uploadTask(with: request, from: jsonData) { (data, response, error) in
            
            let processedResponse = self.handleURLErrors(successCode: 200, data: data, response: response, error: error)
            
            switch processedResponse {
            case .failure(let error):
                result = .failure(error)
            case .success:
                result = .success(())
            }
            
            semaphore.signal()
            
        }.resume()
        
        if semaphore.wait(timeout: timeoutDuration) == .timedOut {
            result = .failure(.timeout)
        }
        
        return result
        
    }
    
    public func updateIdentity(address: ProtocolAddress, serverAddress: String, authToken: String) -> Result<Void, SSAPIEncryptionError> {
        
        guard let store = self.store else {
            return(.failure(.noStore))
        }
        
        guard let userRegistrationId = try? store.localRegistrationId(context: nil) else {
            return(.failure(.userHasNoRegisteredDevice))
        }
        
        let outcome = obtainPreKeyBundle(
            recipient: address,
            sendersRegistrationId: Int(userRegistrationId),
            authToken: authToken,
            serverAddress: serverAddress)
        
        switch outcome {
        case .success(let preKeyBundle):
            do {
                // Store new identity before processing bundle
                let _ = try store.saveIdentity(try preKeyBundle.identityKey(), for: address, context: nil)
                try processPreKeyBundle(
                    preKeyBundle,
                    for: address,
                    sessionStore: store,
                    identityStore: store,
                    context: nil)
                return(.success(()))
            } catch {
                print(error)
                return(.failure(.badFormat))
            }
        case .failure(let error):
            print("Error returned from obtainPreKeyBundle")
            return(.failure(error))
        }
    }
    
    private func handleURLErrors(successCode: Int, data: Data?, response: URLResponse?, error: Error?) -> Result<Void, SSAPIEncryptionError> {
        if error != nil || data == nil {
            return(.failure(.badResponseFromServer))
        }

        guard let response = response as? HTTPURLResponse else {
            return(.failure(.badResponseFromServer))
        }
        
        guard response.statusCode == successCode else {
            do {
                print("Printing data:")
                let jsonToPrint = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
                print(jsonToPrint as Any)
            } catch {
                print("unable to parse JSON")
                let responseString = String(data: data!, encoding: .utf8)
                print("raw response: \(responseString ?? "Not decipherable")")
            }
            
            if response.statusCode == 400 {
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
                    if let code = (json?["code"] as? String) {
                        if code == "invalid_recipient_email" {
                            return(.failure(.badFormat))
                        } else if code == "reached_max_prekeys" {
                            return(.failure(.reachedMaxPreKeys))
                        } else if code == "prekey_id_exists" {
                            return(.failure(.prekeyIdExists))
                        } else {
                            return(.failure(.serverError))
                        }
                    } else {
                        return(.failure(.serverError))
                    }
                } catch {
                    return(.failure(.badResponseFromServer))
                }
            } else if response.statusCode == 403 {
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
                    if let code = (json?["code"] as? String) {
                        if code == "incorrect_arguments" {
                            return(.failure(.badFormat))
                        } else if code == "device_exists" {
                            return(.failure(.deviceExists))
                        } else if code == "device_changed" {
                            return(.failure(.remoteDeviceChanged))
                        } else {
                            return(.failure(.serverError))
                        }
                    } else {
                        return(.failure(.serverError))
                    }
                } catch {
                    return(.failure(.badResponseFromServer))
                }
            } else if response.statusCode == 404 {
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
                    if let code = (json?["code"] as? String) {
                        if code == "no_device" {
                            return(.failure(.senderHasNoRegisteredDevice))
                        } else if code == "no_recipient" {
                            return(.failure(.recipientUserDoesNotExist))
                        } else if code == "no_recipient_device" {
                            return(.failure(.recipientUserHasNoRegisteredDevice))
                        } else {
                            return(.failure(.serverError))
                        }
                    } else {
                        return(.failure(.serverError))
                    }
                } catch {
                    return(.failure(.badResponseFromServer))
                }
            } else if response.statusCode == 429 {
                return(.failure(.requestThrottled))
            } else {
                return(.failure(.serverError))
            }
        }
        
        return(.success(()))
    }
}


