//
//  SimpleSignalSwiftEncryptionAPI.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 19/12/2020.
//

import Foundation

//https://michaellong.medium.com/how-to-chain-api-calls-using-swift-5s-new-result-type-and-gcd-56025b51033c

public class SimpleSignalSwiftEncryptionAPI {
    
    let keychainSwift: KeychainSwift
    var store: KeychainSignalProtocolStore? = nil
    
    init(combinedName: String) throws {
        self.keychainSwift = KeychainSwift(keyPrefix: combinedName)
        self.store = try? KeychainSignalProtocolStore(keychainSwift: keychainSwift)
    }
    
    public func createDevice(keychainSwift: KeychainSwift, username: String, serverAddress: String) -> Result <Void, SSAPIEncryptionUploadDeviceError> {
            
        do {
            let identityKey = try IdentityKeyPair.generate()
            let deviceId = UInt32(1)
            let address = try ProtocolAddress(name: username, deviceId: deviceId)
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
                deviceAddress: try ProtocolAddress(name: keychainSwift.keyPrefix, deviceId: deviceId).combinedValue,
                identityKey: identityKey.identityKey,
                registrationId: registrationId,
                preKeys: allPreKeys,
                signedPreKey: signedPreKeyRecord)
            
            switch result {
            case .success:
                self.store = store
                return .success(())
            case .failure(let error):
                return .failure(error)
            }
            
        } catch {
            return .failure(.badFormat)
        }
    }
    
    private func uploadDevice(serverAddress: String, deviceAddress: String, identityKey: IdentityKey, registrationId: UInt32, preKeys: [PreKeyRecord], signedPreKey: SignedPreKeyRecord) -> Result<Void, SSAPIEncryptionUploadDeviceError> {
        
        let path = "\(serverAddress)/v1/device/"
        guard let url = URL(string: path) else {
            return .failure(.invalidUrl)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let json: [String: Any]
        do {
            json = [
                "address": deviceAddress,
                "identity_key": try identityKey.serialize(),
                "registration_id": registrationId,
                "pre_keys": try preKeys.map({ preKey in
                    return [
                        "key_id": preKey.id,
                        "public_key": try preKey.publicKey().serialize()
                    ]
                }),
                "signed_pre_key": [
                    "key_id": try signedPreKey.id(),
                    "public_key": try signedPreKey.publicKey().serialize(),
                    "signature": try signedPreKey.signature()
                ]
            ]
        } catch {
            return .failure(.badFormat)
        }
        
        print(json)
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: json, options: []) else {
            return .failure(.badFormat)
        }
        
        var result: Result<Void, SSAPIEncryptionUploadDeviceError>!
        
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
                if response.statusCode == 403 {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
                        if let code = (json?["code"] as? String) {
                            if code == "incorrect_arguments" {
                                result = .failure(.badFormat)
                            } else if code == "device_exists" {
                                result = .failure(.deviceExists)
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
        
        _ = semaphore.wait(wallTimeout: .distantFuture)
        
        return result
        
    }
    
    public func sendMessage(message: String, recipient: String, serverAddress: String) -> Result<Void, SSAPIEncryptionSendMessageError> {
        
        guard let store = self.store else {
            return(.failure(.noStore))
        }
        
        do {
            
            let address = try ProtocolAddress(name: recipient, deviceId: 1111)
            
            if (try? store.loadSession(for: address, context: nil)) != nil {
                return (sendMessageUsingStore(message: message, isPreKeyMessage: false, recipientAddress: address, serverAddress: serverAddress))
            } else {
                let deviceId = try store.localRegistrationId(context: nil)
                let preKeyBundleResult = obtainPreKeyBundle(recipient: recipient, sendersDeviceId: Int(deviceId), serverAddress: serverAddress)
                switch preKeyBundleResult {
                case .success(let preKeyBundle):
                    print(preKeyBundle)
                    try processPreKeyBundle(
                        preKeyBundle,
                        for: address,
                        sessionStore: store,
                        identityStore: store,
                        context: nil)
                    return (sendMessageUsingStore(message: message, isPreKeyMessage: true, recipientAddress: address, serverAddress: serverAddress))
                case .failure(let error):
                    return(.failure(error))
                }
            }
            
        } catch {
            return(.failure(.badFormat))
        }
        
    }
    
    private func sendMessageUsingStore(message: String, isPreKeyMessage: Bool, recipientAddress: ProtocolAddress, serverAddress: String) -> Result<Void, SSAPIEncryptionSendMessageError> {
        
        guard let store = self.store else {
            return(.failure(.noStore))
        }
        
        do {
            let cipherText = try signalEncrypt(
                message: message.data(using: .utf8)!,
                for: recipientAddress,
                sessionStore: store,
                identityStore: store,
                context: nil)
            var messageData: [UInt8]
            if isPreKeyMessage {
                messageData = try! PreKeySignalMessage(bytes: try! cipherText.serialize()).serialize()
            } else {
                messageData = try! SignalMessage(bytes: try! cipherText.serialize()).serialize()
            }
            
            guard let deviceId = try? store.localRegistrationId(context: nil) else {
                return(.failure(.senderHasNoRegisteredDevice))
            }
            
            let path = "\(serverAddress)/v1/\(deviceId)/messages"
            guard let url = URL(string: path) else {
                return .failure(.invalidUrl)
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let messageJsonObject = [
                "registration_id": recipientAddress.deviceId,
                "content": messageData
            ] as [String : Any]
            guard let messageJsonData = try? JSONSerialization.data(withJSONObject: messageJsonObject, options: []) else {
                return .failure(.badFormat)
            }
            let messageJsonString = String(data: messageJsonData, encoding: .utf8)
            let bodyJson = [
                "recipient": recipientAddress.name,
                "message": messageJsonString
            ]
            guard let bodyJsonData = try? JSONSerialization.data(withJSONObject: bodyJson, options: []) else {
                return .failure(.badFormat)
            }
            
            
            var result: Result<Void, SSAPIEncryptionSendMessageError>!
            
            let semaphore = DispatchSemaphore(value: 0)
            
            URLSession.shared.uploadTask(with: request, from: bodyJsonData) { (data, response, error) in
                
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
                            let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
                            if let code = (json?["code"] as? String) {
                                if code == "invalid_recipient_email" {
                                    result = .failure(.badFormat)
                                } else {
                                    result = .failure(.serverError)
                                }
                            } else {
                                result = .failure(.serverError)
                            }
                        } catch {
                            result = .failure(.badResponseFromServer)
                        }
                    } else if response.statusCode == 403 {
                        do {
                            let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
                            if let code = (json?["code"] as? String) {
                                if code == "device_changed" {
                                    result = .failure(.sendersDeviceChanged)
                                } else if code == "recipient_identity_changed" {
                                    result = .failure(.recipientsDeviceChanged)
                                } else {
                                    result = .failure(.serverError)
                                }
                            } else {
                                result = .failure(.serverError)
                            }
                        } catch {
                            result = .failure(.badResponseFromServer)
                        }
                    } else if response.statusCode == 404 {
                        do {
                            let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
                            if let code = (json?["code"] as? String) {
                                if code == "no_device" {
                                    result = .failure(.senderHasNoRegisteredDevice)
                                } else if code == "no_recipient" {
                                    result = .failure(.recipientUserDoesNotExist)
                                } else if code == "no_recipient_device" {
                                    result = .failure(.recipientUserHasNoRegisteredDevice)
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
            
            _ = semaphore.wait(wallTimeout: .distantFuture)
            
            return result
        } catch {
            return(.failure(.badFormat))
        }
    }
    
    private func obtainPreKeyBundle(recipient: String, sendersDeviceId: Int, serverAddress: String) -> Result<PreKeyBundle, SSAPIEncryptionSendMessageError> {
        let recipientData = Data(recipient.utf8)
        let recipientHex = recipientData.map{ String(format:"%02x", $0) }.joined()
        let path = "\(serverAddress)/v1/prekeybundle/\(recipientHex)/\(sendersDeviceId)/"
        guard let url = URL(string: path) else {
            return .failure(.invalidUrl)
        }
        
        var result: Result<PreKeyBundle, SSAPIEncryptionSendMessageError>!
        
        let semaphore = DispatchSemaphore(value: 0)
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            
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
                if response.statusCode == 403 {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
                        if let code = (json?["code"] as? String) {
                            if code == "incorrect_arguments" {
                                result = .failure(.badFormat)
                            } else if code == "device_changed" {
                                result = .failure(.sendersDeviceChanged)
                            } else {
                                result = .failure(.serverError)
                            }
                        } else {
                            result = .failure(.serverError)
                        }
                    } catch {
                        result = .failure(.badResponseFromServer)
                    }
                } else if response.statusCode == 404 {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
                        if let code = (json?["code"] as? String) {
                            if code == "no_device" {
                                result = .failure(.senderHasNoRegisteredDevice)
                            } else if code == "no_recipient_device" {
                                result = .failure(.recipientUserHasNoRegisteredDevice)
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
                let decodedResponse = try decoder.decode(SSAPIPreKeyBundleResponse.self, from: data!)
                guard let deviceId = UInt32(decodedResponse.address.split(separator: ".")[1]) else {
                    result = .failure(.badFormat)
                    return
                }
                let preKeyBundle = try PreKeyBundle(
                    registrationId: decodedResponse.registrationId,
                    deviceId: deviceId,
                    prekeyId: decodedResponse.preKey.keyId,
                    prekey: PublicKey(decodedResponse.preKey.publicKey),
                    signedPrekeyId: decodedResponse.signedPreKey.keyId,
                    signedPrekey: PublicKey(decodedResponse.signedPreKey.publicKey),
                    signedPrekeySignature: decodedResponse.signedPreKey.signature,
                    identity: IdentityKey(bytes: decodedResponse.identityKey))
                result = .success(preKeyBundle)
            } catch {
                result = .failure(.badResponseFromServer)
            }
            
            semaphore.signal()
            
        }.resume()
        
        _ = semaphore.wait(wallTimeout: .distantFuture)
        
        return result
    }
    
    public func getMessages(serverAddress: String) -> Result<[Result<SSAPIGetMessagesOutput, SSAPIEncryptionGetMessagesError>], SSAPIEncryptionGetMessagesError> {
        
        guard let store = self.store else {
            return(.failure(.noStore))
        }
        
        guard let recipientRegistrationId = try? store.localRegistrationId(context: nil) else {
            return(.failure(.userHasNoRegisteredDevice))
        }
        
        let path = "\(serverAddress)/v1/prekeybundle/\(recipientRegistrationId)/messages/"
        guard let url = URL(string: path) else {
            return .failure(.invalidUrl)
        }
        
        var result: Result<[Result<SSAPIGetMessagesOutput, SSAPIEncryptionGetMessagesError>], SSAPIEncryptionGetMessagesError>!
        
        let semaphore = DispatchSemaphore(value: 0)
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            
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
                if response.statusCode == 403 {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
                        if let code = (json?["code"] as? String) {
                            if code == "incorrect_arguments" {
                                result = .failure(.badFormat)
                            } else if code == "device_changed" {
                                result = .failure(.userDeviceChanged)
                            } else {
                                result = .failure(.serverError)
                            }
                        } else {
                            result = .failure(.serverError)
                        }
                    } catch {
                        result = .failure(.badResponseFromServer)
                    }
                } else if response.statusCode == 404 {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
                        if let code = (json?["code"] as? String) {
                            if code == "no_device" {
                                result = .failure(.userHasNoRegisteredDevice)
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
                var output: [Result<SSAPIGetMessagesOutput, SSAPIEncryptionGetMessagesError>] = []
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let decodedResponse = try decoder.decode([SSAPIGetMessagesResponse].self, from: data!)
                for input in decodedResponse {
                    output.append(self.decryptMessage(input: input))
                }
                result = .success(output)
            } catch {
                result = .failure(.badResponseFromServer)
            }
            
            semaphore.signal()
            
        }.resume()
        
        _ = semaphore.wait(wallTimeout: .distantFuture)
        
        return result
    }
    
    private func decryptMessage(input: SSAPIGetMessagesResponse) -> Result<SSAPIGetMessagesOutput, SSAPIEncryptionGetMessagesError> {
        
        guard let store = self.store else {
            return(.failure(.noStore))
        }
        
        let address: ProtocolAddress
        do {
            address = try ProtocolAddress(input.senderAddress)
        } catch {
            return(.failure(.invalidSenderAddress))
        }
        let decryptedMessageString: String
        do {
            let decryptedMessageData = try signalDecrypt(
                message: SignalMessage(bytes: input.content),
                from: address,
                sessionStore: store,
                identityStore: store,
                context: nil)

            decryptedMessageString = String(decoding: decryptedMessageData, as: UTF8.self)
        } catch {
            do {
                let decryptedMessageData = try signalDecryptPreKey(
                    message: PreKeySignalMessage(bytes: input.content),
                    from: address,
                    sessionStore: store,
                    identityStore: store,
                    preKeyStore: store,
                    signedPreKeyStore: store,
                    context: nil)
                decryptedMessageString = String(decoding: decryptedMessageData, as: UTF8.self)
            } catch {
                return(.failure(.unableToDecrypt))
            }
        }
        let output = SSAPIGetMessagesOutput(message: decryptedMessageString, senderAddress: address)
        return(.success(output))
        
    }
    
    public func deleteDevice(serverAddress: String) -> Result<Void, SSAPIEncryptionDeleteDeviceError> {
        
        let path = "\(serverAddress)/v1/devices/"
        guard let url = URL(string: path) else {
            return .failure(.invalidUrl)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        var result: Result<Void, SSAPIEncryptionDeleteDeviceError>!
        
        let semaphore = DispatchSemaphore(value: 0)
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            
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
                if response.statusCode == 404 {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
                        if let code = (json?["code"] as? String) {
                            if code == "no_device" {
                                result = .failure(.userHasNoRegisteredDevice)
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
        
        _ = semaphore.wait(wallTimeout: .distantFuture)
        
        return result
    }
    
    public func deleteMessage(serverAddress: String, messageIds: [Int]) -> Result<[Int: SSAPIDeleteMessageOutcome], SSAPIEncryptionDeleteMessagesError> {
        
        guard let store = self.store else {
            return(.failure(.noStore))
        }
        
        guard let localRegistrationId = try? store.localRegistrationId(context: nil) else {
            return(.failure(.userHasNoRegisteredDevice))
        }
        
        let path = "\(serverAddress)/\(localRegistrationId)/messages/"
        guard let url = URL(string: path) else {
            return .failure(.invalidUrl)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        var result: Result<[Int: SSAPIDeleteMessageOutcome], SSAPIEncryptionDeleteMessagesError>!
        
        let semaphore = DispatchSemaphore(value: 0)
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            
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
                if response.statusCode == 403 {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
                        if let code = (json?["code"] as? String) {
                            if code == "incorrect_arguments" {
                                result = .failure(.badFormat)
                            } else if code == "device_changed" {
                                result = .failure(.userDeviceChanged)
                            } else {
                                result = .failure(.serverError)
                            }
                        } else {
                            result = .failure(.serverError)
                        }
                    } catch {
                        result = .failure(.badResponseFromServer)
                    }
                } else if response.statusCode == 404 {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
                        if let code = (json?["code"] as? String) {
                            if code == "no_device" {
                                result = .failure(.userHasNoRegisteredDevice)
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
                var output: [Int: SSAPIDeleteMessageOutcome] = [:]
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let decodedResponse = try decoder.decode([String].self, from: data!)
                for (index, outcomeCode) in decodedResponse.enumerated() {
                    guard let messageId = messageIds[safe: index] else {
                        throw SSAPIEncryptionDeleteMessagesError.badResponseFromServer
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
                result = .failure(.badResponseFromServer)
            }
            
            semaphore.signal()
            
        }.resume()
        
        _ = semaphore.wait(wallTimeout: .distantFuture)
        
        return result
    }
    
    private func updatePreKeys(serverAddress: String) -> Result<Void, SSAPIEncryptionUpdatePrekeyError> {
        
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
        var json: [[String: Any]] = []
        do {
            for preKey in allPreKeys {
                json.append([
                    "key_id": preKey.id,
                    "public_key": try preKey.publicKey().serialize()
                ])
            }
        } catch {
            return .failure(.badFormat)
        }
        
        print(json)
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: json, options: []) else {
            return .failure(.badFormat)
        }
        
        var result: Result<Void, SSAPIEncryptionUpdatePrekeyError>!
        
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
                        let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
                        if let code = (json?["code"] as? String) {
                            if code == "reached_max_prekeys" {
                                result = .failure(.reachedMaxPreKeys)
                            } else if code == "prekey_id_exists" {
                                result = .failure(.prekeyIdExists)
                            } else {
                                result = .failure(.serverError)
                            }
                        } else {
                            result = .failure(.serverError)
                        }
                    } catch {
                        result = .failure(.badResponseFromServer)
                    }
                } else if response.statusCode == 403 {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
                        if let code = (json?["code"] as? String) {
                            if code == "incorrect_arguments" {
                                result = .failure(.badFormat)
                            } else if code == "device_changed" {
                                result = .failure(.deviceChanged)
                            } else {
                                result = .failure(.serverError)
                            }
                        } else {
                            result = .failure(.serverError)
                        }
                    } catch {
                        result = .failure(.badResponseFromServer)
                    }
                } else if response.statusCode == 404 {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
                        if let code = (json?["code"] as? String) {
                            if code == "no_device" {
                                result = .failure(.userHasNoDevice)
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
        
        _ = semaphore.wait(wallTimeout: .distantFuture)
        
        return result
        
    }
    
    private func updateSignedPreKey(serverAddress: String) -> Result<Void, SSAPIEncryptionUpdateSignedPrekeyError> {
        
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
        let json: [String: Any]
        do {
            json = [
                "key_id": signedPreKeyRecord.id,
                "public_key": try signedPreKeyRecord.publicKey().serialize(),
                "signature": try signedPreKeyRecord.signature()
            ]
        } catch {
            return(.failure(.badFormat))
        }
        
        print(json)
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: json, options: []) else {
            return .failure(.badFormat)
        }
        
        var result: Result<Void, SSAPIEncryptionUpdateSignedPrekeyError>!
        
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
                if response.statusCode == 403 {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
                        if let code = (json?["code"] as? String) {
                            if code == "incorrect_arguments" {
                                result = .failure(.badFormat)
                            } else if code == "device_changed" {
                                result = .failure(.deviceChanged)
                            } else {
                                result = .failure(.serverError)
                            }
                        } else {
                            result = .failure(.serverError)
                        }
                    } catch {
                        result = .failure(.badResponseFromServer)
                    }
                } else if response.statusCode == 404 {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
                        if let code = (json?["code"] as? String) {
                            if code == "no_device" {
                                result = .failure(.userHasNoDevice)
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
        
        _ = semaphore.wait(wallTimeout: .distantFuture)
        
        return result
        
    }
}

extension Collection {
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension ProtocolAddress {
    
    convenience init(_ combinedValue: String) throws {
        let splitValues = combinedValue.split(separator: ".")
        guard splitValues.count == 2 else {
            throw SSAPIProtocolAddressError.incorrectNumberOfComponents
        }
        let name = String(splitValues[0])
        guard let deviceId = UInt32(splitValues[1]) else {
            throw SSAPIProtocolAddressError.deviceIdIsNotInt
        }
        try self.init(name: name, deviceId: deviceId)
    }
    
    var combinedValue: String {
        return "\(self.name).\(self.deviceId)"
    }
}

extension Date {
    var ticks: UInt64 {
        return UInt64((self.timeIntervalSince1970 + 62_135_596_800) * 10_000_000)
    }
}
