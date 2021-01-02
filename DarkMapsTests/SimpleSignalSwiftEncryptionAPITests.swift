//
//  SimpleSignalSwiftEncryptionAPITests.swift
//  SignalMapsTests
//
//  Created by Matthew Roche on 23/12/2020.
//

import XCTest

@testable import DarkMaps

import Mockingjay

class SimpleSignalSwiftEncryptionAPITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let keychainSwift = KeychainSwift()
        keychainSwift.clear()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
        
    func testCreateDevice() throws {
        let expectation = XCTestExpectation(description: "Successfully creates and uploads device")
        let uriValue = "https://api.dark-maps.com/v1/devices/"
        let data: NSDictionary = [
            "code": "device_created",
            "message": "Device successfully created"
        ]
        self.stub(uri(uriValue), json(data, status: 201))
        
        let address = try ProtocolAddress(name: "testName", deviceId: 1)
        let encryptionAPI = try SimpleSignalSwiftEncryptionAPI(address: address)
        
        let result = encryptionAPI.createDevice(authToken: "testAuthToken", serverAddress: "https://api.dark-maps.com")
        
        print(result)
        
        switch result {
        case .success(let _):
            expectation.fulfill()
        case .failure(let error):
            print(error)
        }
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testSendPreKeyMessage() throws {
        let expectation = XCTestExpectation(description: "Successfully obtains prekey bundle and sends message")
        
        let uriValue = "https://api.dark-maps.com/v1/devices/"
        let data: NSDictionary = [
            "code": "device_created",
            "message": "Device successfully created"
        ]
        self.stub(uri(uriValue), json(data, status: 201))
        
        let address = try ProtocolAddress(name: "testName", deviceId: 1)
        let encryptionAPI = try SimpleSignalSwiftEncryptionAPI(address: address)
        let _ = encryptionAPI.createDevice(authToken: "testAuthToken", serverAddress: "https://api.dark-maps.com")
        
        let registrationId = KeychainSwift().get("testName.1-enc-registrationId")!
        
        let recipient = "testRecipient"
        let recipientRegistrationId = 1234
        let recipientDeviceId = 1
        let recipientAddress = try ProtocolAddress(name: recipient, deviceId: UInt32(recipientDeviceId))
        let recipientData = Data(recipientAddress.combinedValue.utf8)
        let recipientHex = recipientData.map{ String(format:"%02x", $0) }.joined()
        let recipientIdentity = try IdentityKeyPair.generate()
        let recipientPrekeyId = 1
        let recipientPrekey = try PreKeyRecord.init(id: UInt32(1), privateKey: try PrivateKey.generate())
        let recipientSignedPrekeyId = 1
        let recipientSignedPrekey = try PrivateKey.generate()
        let recipientSignedPrekeySignature = try recipientIdentity.privateKey.generateSignature(
            message: recipientSignedPrekey.publicKey().serialize()
        )
        let recipientSignedPreKeyRecord = try SignedPreKeyRecord.init(
            id: UInt32(recipientSignedPrekeyId),
            timestamp: Date().ticks,
            privateKey: recipientSignedPrekey,
            signature: recipientSignedPrekeySignature)
        
        let uriValue2 = "https://api.dark-maps.com/v1/prekeybundles/\(recipientHex)/\(registrationId)/"
        let data2: NSDictionary = [
            "address": recipientAddress.combinedValue,
            "identity_key": try recipientIdentity.publicKey.serialize().toBase64String(),
            "registration_id": recipientRegistrationId,
            "pre_key": [
                "key_id": UInt32(recipientPrekeyId),
                "public_key": try recipientPrekey.publicKey().serialize().toBase64String()
            ],
            "signed_pre_key": [
                "key_id": UInt32(recipientSignedPrekeyId),
                "public_key": try recipientSignedPreKeyRecord.publicKey().serialize().toBase64String(),
                "signature": try recipientSignedPreKeyRecord.signature().toBase64String()
            ]
        ]
        self.stub(uri(uriValue2), json(data2, status: 200))
        
        let uriValue3 = "https://api.dark-maps.com/v1/\(registrationId)/messages/"
        let data3: NSDictionary = [
            "id": 1,
            "content": "testEncryptedContent",
            "sender_address": address.combinedValue,
            "sender_registration_id": registrationId,
            "recipient_address": recipientAddress.combinedValue
        ]
        self.stub(uri(uriValue3), json(data3, status: 201))
        
        let result = encryptionAPI.sendMessage(message: "testMessage", recipientName: recipient, recipientDeviceId: UInt32(recipientDeviceId), authToken: "testAuthToken", serverAddress: "https://api.dark-maps.com")
        
        print(result)
        
        switch result {
        case .success():
            expectation.fulfill()
        case .failure(let error):
            print(error)
        }
        wait(for: [expectation], timeout: 2.0)
        
    }
    
    func testSendStandardMessage() throws {
        let expectation = XCTestExpectation(description: "Successfully obtains sends message when a session already exists")
        
        let uriValue = "https://api.dark-maps.com/v1/devices/"
        let data: NSDictionary = [
            "code": "device_created",
            "message": "Device successfully created"
        ]
        self.stub(uri(uriValue), json(data, status: 201))
        
        let address = try ProtocolAddress(name: "testName", deviceId: 1)
        let encryptionAPI = try SimpleSignalSwiftEncryptionAPI(address: address)
        let _ = encryptionAPI.createDevice(authToken: "testAuthToken", serverAddress: "https://api.dark-maps.com")
        
        let registrationId = KeychainSwift().get("testName.1-enc-registrationId")!
        
        let recipient = "testRecipient"
        let recipientRegistrationId = 1234
        let recipientDeviceId = 1
        let recipientAddress = try ProtocolAddress(name: recipient, deviceId: UInt32(recipientDeviceId))
        let recipientData = Data(recipientAddress.combinedValue.utf8)
        let recipientHex = recipientData.map{ String(format:"%02x", $0) }.joined()
        let recipientIdentity = try IdentityKeyPair.generate()
        let recipientPrekeyId = 1
        let recipientPrekey = try PreKeyRecord.init(id: UInt32(1), privateKey: try PrivateKey.generate())
        let recipientSignedPrekeyId = 1
        let recipientSignedPrekey = try PrivateKey.generate()
        let recipientSignedPrekeySignature = try recipientIdentity.privateKey.generateSignature(
            message: recipientSignedPrekey.publicKey().serialize()
        )
        let recipientSignedPreKeyRecord = try SignedPreKeyRecord.init(
            id: UInt32(recipientSignedPrekeyId),
            timestamp: Date().ticks,
            privateKey: recipientSignedPrekey,
            signature: recipientSignedPrekeySignature)
        
        let uriValue2 = "https://api.dark-maps.com/v1/prekeybundles/\(recipientHex)/\(registrationId)/"
        let data2: NSDictionary = [
            "address": recipientAddress.combinedValue,
            "identity_key": try recipientIdentity.publicKey.serialize().toBase64String(),
            "registration_id": recipientRegistrationId,
            "pre_key": [
                "key_id": UInt32(recipientPrekeyId),
                "public_key": try recipientPrekey.publicKey().serialize().toBase64String()
            ],
            "signed_pre_key": [
                "key_id": UInt32(recipientSignedPrekeyId),
                "public_key": try recipientSignedPreKeyRecord.publicKey().serialize().toBase64String(),
                "signature": try recipientSignedPreKeyRecord.signature().toBase64String()
            ]
        ]
        self.stub(uri(uriValue2), json(data2, status: 200))
        
        let uriValue3 = "https://api.dark-maps.com/v1/\(registrationId)/messages/"
        let data3: NSDictionary = [
            "id": 1,
            "content": "testEncryptedContent",
            "sender_address": address.combinedValue,
            "sender_registration_id": registrationId,
            "recipient_address": recipientAddress.combinedValue
        ]
        self.stub(uri(uriValue3), json(data3, status: 201))
        
        let senderStore = encryptionAPI.exposePrivateStore()!
        let preKeyBundle = try PreKeyBundle(registrationId: UInt32(recipientRegistrationId), deviceId: UInt32(recipientDeviceId), prekeyId: UInt32(recipientPrekeyId), prekey: try recipientPrekey.publicKey(), signedPrekeyId: UInt32(recipientSignedPrekeyId), signedPrekey: try recipientSignedPreKeyRecord.publicKey(), signedPrekeySignature: recipientSignedPrekeySignature, identity: recipientIdentity.identityKey)
        try processPreKeyBundle(preKeyBundle,
                            for: recipientAddress,
                            sessionStore: senderStore,
                            identityStore: senderStore,
                            context: nil)
        let cipherTextForPreKeyMessage = try signalEncrypt(
            message: "message".data(using: .utf8)!,
            for: recipientAddress,
            sessionStore: senderStore,
            identityStore: senderStore,
            context: nil)
        var preKeyMessage = try PreKeySignalMessage(bytes: try cipherTextForPreKeyMessage.serialize())
        let recipientStore = try KeychainSignalProtocolStore(
            keychainSwift: KeychainSwift(keyPrefix: "test2"),
            address: recipientAddress,
            identity: recipientIdentity,
            registrationId: UInt32(recipientRegistrationId))
        try recipientStore.storePreKey(recipientPrekey, id: UInt32(recipientPrekeyId), context: nil)
        try recipientStore.storeSignedPreKey(recipientSignedPreKeyRecord, id: UInt32(recipientSignedPrekeyId), context: nil)
        let _ = try signalDecryptPreKey(
            message: preKeyMessage,
            from: address,
            sessionStore: recipientStore,
            identityStore: recipientStore,
            preKeyStore: recipientStore,
            signedPreKeyStore: recipientStore,
            context: nil)
        let cipherTextForReturnMessage = try signalEncrypt(
            message: "message".data(using: .utf8)!,
            for: address,
            sessionStore: recipientStore,
            identityStore: recipientStore,
            context: nil)
        var standardMessage = try SignalMessage(bytes: try cipherTextForReturnMessage.serialize())
        let _ = try signalDecrypt(
            message: standardMessage,
            from: recipientAddress,
            sessionStore: senderStore,
            identityStore: senderStore,
            context: nil)
        
        XCTAssertNotNil(try senderStore.loadSession(for: recipientAddress, context: nil))
        
        let result = encryptionAPI.sendMessage(message: "testMessage", recipientName: recipient, recipientDeviceId: UInt32(recipientDeviceId), authToken: "testAuthToken", serverAddress: "https://api.dark-maps.com")
        
        print(result)
        
        switch result {
        case .success():
            expectation.fulfill()
        case .failure(let error):
            print(error)
        }
        wait(for: [expectation], timeout: 2.0)
        
    }
    
    func testGetMessages() throws {
        
        let expectation = XCTestExpectation(description: "Successfully retrieves and decrypts a message")
        
        //Set up users
        let sender = "testSender"
        let senderRegistrationId = 1234
        let senderDeviceId = 1
        let senderAddress = try ProtocolAddress(name: sender, deviceId: UInt32(senderDeviceId))
        let senderIdentity = try IdentityKeyPair.generate()
        let senderPreKey = try PreKeyRecord.init(id: UInt32(1), privateKey: try PrivateKey.generate())
        let senderSignedPrekeyId = 1
        let senderSignedPrekey = try PrivateKey.generate()
        let senderSignedPrekeySignature = try senderIdentity.privateKey.generateSignature(
            message: senderSignedPrekey.publicKey().serialize()
        )
        let senderSignedPreKeyRecord = try SignedPreKeyRecord.init(
            id: UInt32(senderSignedPrekeyId),
            timestamp: Date().ticks,
            privateKey: senderSignedPrekey,
            signature: senderSignedPrekeySignature)
        let senderStore = InMemorySignalProtocolStore.init(
            identity: senderIdentity,
            deviceId: UInt32(senderDeviceId))
        try senderStore.storePreKey(
            senderPreKey,
            id: 1,
            context: nil)
        try senderStore.storeSignedPreKey(
            senderSignedPreKeyRecord,
            id: 1,
            context: nil)
        
        let uriValue = "https://api.dark-maps.com/v1/devices/"
        let data: NSDictionary = [
            "code": "device_created",
            "message": "Device successfully created"
        ]
        self.stub(uri(uriValue), json(data, status: 201))
        
        let recipient = "testRecipient"
        let recipientDeviceId = UInt32(1)
        let recipientAddress = try ProtocolAddress(name: recipient, deviceId: UInt32(recipientDeviceId))
        let encryptionAPI = try SimpleSignalSwiftEncryptionAPI(address: recipientAddress)
        let _ = encryptionAPI.createDevice(authToken: "testAuthToken", serverAddress: "https://api.dark-maps.com")
        
        let recipientRegistrationId = UInt32(KeychainSwift().get("\(recipientAddress.combinedValue)-enc-registrationId")!)!
        let recipientIdentity = try IdentityKeyPair(bytes: KeychainSwift().getData("\(recipientAddress.combinedValue)-enc-privateKey")!)
        let recipientPrekey = try PreKeyRecord(bytes: (KeychainSwift().getData("\(recipientAddress.combinedValue)-enc-preKey:1"))!)
        let recipientSignedPreKeyRecord = try SignedPreKeyRecord(bytes: KeychainSwift().getData("\(recipientAddress.combinedValue)-enc-signedPreKey:1")!)
        
        let recipientPreKeyBundle = try PreKeyBundle.init(
            registrationId: recipientRegistrationId,
            deviceId: recipientDeviceId,
            prekeyId: try recipientPrekey.id(),
            prekey: try recipientPrekey.publicKey(),
            signedPrekeyId: try recipientSignedPreKeyRecord.id(),
            signedPrekey: try recipientSignedPreKeyRecord.publicKey(),
            signedPrekeySignature: try recipientSignedPreKeyRecord.signature(),
            identity: recipientIdentity.identityKey)
        
        try processPreKeyBundle(
            recipientPreKeyBundle,
            for: recipientAddress,
            sessionStore: senderStore,
            identityStore: senderStore,
            context: nil)
        
        let messageText = "A test message"
        let cipherText = try signalEncrypt(
            message: messageText.data(using: .utf8)!,
            for: recipientAddress,
            sessionStore: senderStore,
            identityStore: senderStore,
            context: nil)
        
        let message = try! PreKeySignalMessage(bytes: try! cipherText.serialize())
        
        let uriValue2 = "https://api.dark-maps.com/v1/\(recipientRegistrationId)/messages/"
        print(uriValue2)
        let contentObject = [
            "registration_id": senderRegistrationId,
            "content": try message.serialize().toBase64String()
        ] as [String : Any]
        let contentJsonData = try! JSONSerialization.data(withJSONObject: contentObject, options: [])
        let contentText = String(data: contentJsonData, encoding: .utf8)!
        print(messageText)
        let messageInArray: NSDictionary = [
            "id": 1,
            "content": contentText,
            "recipient_address": recipientAddress.combinedValue,
            "sender_registration_id": senderRegistrationId,
            "sender_address": senderAddress.combinedValue
        ]
        let data2: NSArray = [messageInArray]
        
        self.stub(uri(uriValue2), json(data2, status: 200))
        
        let result = encryptionAPI.getMessages(authToken: "testAuthToken", serverAddress: "https://api.dark-maps.com")
        
        switch result {
        case .success(let decryptedMessages):
            XCTAssertEqual(decryptedMessages.count, 1)
            XCTAssertEqual(decryptedMessages[0].message, messageText)
            XCTAssertEqual(decryptedMessages[0].senderAddress.combinedValue, senderAddress.combinedValue)
            expectation.fulfill()
            
        case .failure(let error):
            print(error)
        }
        wait(for: [expectation], timeout: 2.0)
        
    }
    
    func testDeleteDevice() throws {
        let expectation = XCTestExpectation(description: "Successfully delete a device")
        
        let uriValue = "https://api.dark-maps.com/v1/devices/"
        let data: NSDictionary = [
            "code": "device_created",
            "message": "Device successfully created"
        ]
        self.stub(uri(uriValue), json(data, status: 201))
        
        let name = "testRecipient"
        let deviceId = UInt32(1)
        let address = try ProtocolAddress(name: name, deviceId: UInt32(deviceId))
        let encryptionAPI = try SimpleSignalSwiftEncryptionAPI(address: address)
        let _ = encryptionAPI.createDevice(authToken: "testAuthToken", serverAddress: "https://api.dark-maps.com")
        
        let uriValue2 = "https://api.dark-maps.com/v1/devices/"
        self.stub(uri(uriValue2), http(204))
        
        let result = encryptionAPI.deleteDevice(authToken: "testAuthToken", serverAddress: "https://api.dark-maps.com")
        
        switch result {
        case .success():
            let loadedRegistrationId = KeychainSwift().get("\(address.combinedValue)-enc-registrationId")
            XCTAssertNil(loadedRegistrationId)
            expectation.fulfill()
        case .failure(let error):
            print(error)
        }
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testDeleteMessage() throws {
        let expectation = XCTestExpectation(description: "Successfully delete a message")
        
        let uriValue = "https://api.dark-maps.com/v1/devices/"
        let data: NSDictionary = [
            "code": "device_created",
            "message": "Device successfully created"
        ]
        self.stub(uri(uriValue), json(data, status: 201))
        
        let name = "testRecipient"
        let deviceId = UInt32(1)
        let address = try ProtocolAddress(name: name, deviceId: UInt32(deviceId))
        let encryptionAPI = try SimpleSignalSwiftEncryptionAPI(address: address)
        let _ = encryptionAPI.createDevice(authToken: "testAuthToken", serverAddress: "https://api.dark-maps.com")
        
        let registrationId = UInt32(KeychainSwift().get("\(address.combinedValue)-enc-registrationId")!)!
        
        let uriValue2 = "https://api.dark-maps.com/v1/\(registrationId)/messages/"
        let data2: NSArray = [
            "message_deleted"
        ]
        self.stub(uri(uriValue2), json(data2, status: 200))
        
        let result = encryptionAPI.deleteMessage(authToken: "testAuthToken", serverAddress: "https://api.dark-maps.com", messageIds: [1])
        
        switch result {
        case .success(let outcomeArray):
            XCTAssertEqual(outcomeArray.count, 1)
            XCTAssertEqual(outcomeArray[1], SSAPIDeleteMessageOutcome.messageDeleted)
            expectation.fulfill()
        case .failure(let error):
            print(error)
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testUpdatePreKeys() throws {
        
        let expectation = XCTestExpectation(description: "Successfully updates prekeys")
        
        let uriValue = "https://api.dark-maps.com/v1/devices/"
        let data: NSDictionary = [
            "code": "device_created",
            "message": "Device successfully created"
        ]
        self.stub(uri(uriValue), json(data, status: 201))
        
        let name = "testRecipient"
        let deviceId = UInt32(1)
        let address = try ProtocolAddress(name: name, deviceId: UInt32(deviceId))
        let encryptionAPI = try SimpleSignalSwiftEncryptionAPI(address: address)
        let _ = encryptionAPI.createDevice(authToken: "testAuthToken", serverAddress: "https://api.dark-maps.com")
        
        let registrationId = UInt32(KeychainSwift().get("\(address.combinedValue)-enc-registrationId")!)!
        
        let allKeys = KeychainSwift().allKeys
        for key in allKeys {
            if key.starts(with: "\(address.combinedValue)-enc-preKey") {
                print("Deleting key: \(key)")
                KeychainSwift().delete(key)
            }
        }
        
        let uriValue2 = "https://api.dark-maps.com/v1/\(registrationId)/prekeys/"
        let data2: NSDictionary = [
            "code": "prekeys_stored",
            "message": "Prekeys successfully stored"
        ]
        self.stub(uri(uriValue2), json(data2, status: 200))
        
        let result = encryptionAPI.updatePreKeys(authToken: "testAuthToken", serverAddress: "https://api.dark-maps.com")
        
        switch result {
        case .success():
            expectation.fulfill()
        case .failure(let error):
            print(error)
        }
        
        wait(for: [expectation], timeout: 2.0)
        
    }
    
    func testUpdateSignedPreKey() throws {
        
        let expectation = XCTestExpectation(description: "Successfully updates signed prekeys")
        
        let uriValue = "https://api.dark-maps.com/v1/devices/"
        let data: NSDictionary = [
            "code": "device_created",
            "message": "Device successfully created"
        ]
        self.stub(uri(uriValue), json(data, status: 201))
        
        let name = "testRecipient"
        let deviceId = UInt32(1)
        let address = try ProtocolAddress(name: name, deviceId: UInt32(deviceId))
        let encryptionAPI = try SimpleSignalSwiftEncryptionAPI(address: address)
        let _ = encryptionAPI.createDevice(authToken: "testAuthToken", serverAddress: "https://api.dark-maps.com")
        
        let registrationId = UInt32(KeychainSwift().get("\(address.combinedValue)-enc-registrationId")!)!
        
        let currentSignedPreKey = try SignedPreKeyRecord(bytes: KeychainSwift().getData("\(address.combinedValue)-enc-signedPreKey:1")!)
        let newSignedPreKey = try SignedPreKeyRecord(
            id: try currentSignedPreKey.id(),
            timestamp: try currentSignedPreKey.timestamp() - 532000000000,
            privateKey: try currentSignedPreKey.privateKey(),
            signature: try currentSignedPreKey.signature())
        KeychainSwift().set(Data(try newSignedPreKey.serialize()), forKey: "\(address.combinedValue)-enc-signedPreKey:1")
        
        let uriValue2 = "https://api.dark-maps.com/v1/\(registrationId)/signedprekeys/"
        let data2: NSDictionary = [
            "code": "signed_prekey_stored",
            "message": "Signed prekey successfully stored"
        ]
        self.stub(uri(uriValue2), json(data2, status: 200))
        
        let result = encryptionAPI.updateSignedPreKey(authToken: "testAuthToken", serverAddress: "https://api.dark-maps.com")
        
        switch result {
        case .success():
            expectation.fulfill()
        case .failure(let error):
            print(error)
        }
        
        wait(for: [expectation], timeout: 2.0)
        
    }
}
