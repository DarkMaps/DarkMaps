//
//  SimpleSignalSwiftEncryptionAPITests.swift
//  SignalMapsTests
//
//  Created by Matthew Roche on 23/12/2020.
//

import XCTest

@testable import SignalMaps

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
        let uriValue = "https://www.simplesignal.co.uk/v1/device/"
        let data: NSDictionary = [
            "code": "device_created",
            "message": "Device successfully created"
        ]
        self.stub(uri(uriValue), json(data, status: 201))
        
        let address = try ProtocolAddress(name: "testName", deviceId: 1)
        let encryptionAPI = try SimpleSignalSwiftEncryptionAPI(address: address)
        
        let result = encryptionAPI.createDevice(address: address, serverAddress: "https://www.simplesignal.co.uk")
        
        print(result)
        
        switch result {
        case .success():
            expectation.fulfill()
        case .failure(let error):
            print(error)
        }
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testSendMessage() throws {
        let expectation = XCTestExpectation(description: "Successfully obtains prekey bundle and sends message")
        
        let uriValue = "https://www.simplesignal.co.uk/v1/device/"
        let data: NSDictionary = [
            "code": "device_created",
            "message": "Device successfully created"
        ]
        self.stub(uri(uriValue), json(data, status: 201))
        
        let address = try ProtocolAddress(name: "testName", deviceId: 1)
        let encryptionAPI = try SimpleSignalSwiftEncryptionAPI(address: address)
        let _ = encryptionAPI.createDevice(address: address, serverAddress: "https://www.simplesignal.co.uk")
        
        let registrationId = KeychainSwift().get("testName.1registrationId")!
        
        let recipient = "testRecipient"
        let recipientData = Data(recipient.utf8)
        let recipientHex = recipientData.map{ String(format:"%02x", $0) }.joined()
        let recipientRegistrationId = 1234
        let recipientDeviceId = 1
        let recipientAddress = try ProtocolAddress(name: recipient, deviceId: UInt32(recipientDeviceId))
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
        
        let uriValue2 = "https://www.simplesignal.co.uk/v1/prekeybundle/\(recipientHex)/\(registrationId)/"
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
        
        let uriValue3 = "https://www.simplesignal.co.uk/v1/\(registrationId)/messages/"
        let data3: NSDictionary = [
            "id": 1,
            "content": "testEncryptedContent",
            "sender_address": address.combinedValue,
            "sender_registration_id": registrationId,
            "recipient_address": recipientAddress.combinedValue
        ]
        self.stub(uri(uriValue3), json(data3, status: 201))
        
        let result = encryptionAPI.sendMessage(message: "testMessage", recipient: recipient, serverAddress: "https://www.simplesignal.co.uk")
        
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
        
        let uriValue = "https://www.simplesignal.co.uk/v1/device/"
        let data: NSDictionary = [
            "code": "device_created",
            "message": "Device successfully created"
        ]
        self.stub(uri(uriValue), json(data, status: 201))
        
        let recipient = "testRecipient"
        let recipientDeviceId = UInt32(1)
        let recipientAddress = try ProtocolAddress(name: recipient, deviceId: UInt32(recipientDeviceId))
        let encryptionAPI = try SimpleSignalSwiftEncryptionAPI(address: recipientAddress)
        let _ = encryptionAPI.createDevice(address: recipientAddress, serverAddress: "https://www.simplesignal.co.uk")
        
        let recipientRegistrationId = UInt32(KeychainSwift().get("\(recipientAddress.combinedValue)registrationId")!)!
        let recipientIdentity = try IdentityKeyPair(bytes: KeychainSwift().getData("\(recipientAddress.combinedValue)privateKey")!)
        let recipientPrekey = try PreKeyRecord(bytes: (KeychainSwift().getData("\(recipientAddress.combinedValue)preKey:1"))!)
        let recipientSignedPreKeyRecord = try SignedPreKeyRecord(bytes: KeychainSwift().getData("\(recipientAddress.combinedValue)signedPreKey:1")!)
        
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
        
        let uriValue2 = "https://www.simplesignal.co.uk/v1/prekeybundle/\(recipientRegistrationId)/messages/"
        print(uriValue2)
        let messageInArray: NSDictionary = [
            "id": 1,
            "created": Date().ticks,
            "content": try message.serialize().toBase64String(),
            "sender_registration_id": senderRegistrationId,
            "sender_address": senderAddress.combinedValue
        ]
        let data2: NSArray = [messageInArray]
        
        self.stub(uri(uriValue2), json(data2, status: 200))
        
        let result = encryptionAPI.getMessages(serverAddress: "https://www.simplesignal.co.uk")
        
        switch result {
        case .success(let decryptedMessages):
            XCTAssertEqual(decryptedMessages.count, 1)
            switch decryptedMessages[0] {
            case .success(let output):
                XCTAssertEqual(output.message, messageText)
                XCTAssertEqual(output.senderAddress.combinedValue, senderAddress.combinedValue)
                expectation.fulfill()
            case .failure(let error):
                print(error)
            }
            
        case .failure(let error):
            print(error)
        }
        wait(for: [expectation], timeout: 2.0)
        
    }
    
    func testDeleteDevice() throws {
        let expectation = XCTestExpectation(description: "Successfully delete a device")
        
        let uriValue = "https://www.simplesignal.co.uk/v1/device/"
        let data: NSDictionary = [
            "code": "device_created",
            "message": "Device successfully created"
        ]
        self.stub(uri(uriValue), json(data, status: 201))
        
        let name = "testRecipient"
        let deviceId = UInt32(1)
        let address = try ProtocolAddress(name: name, deviceId: UInt32(deviceId))
        let encryptionAPI = try SimpleSignalSwiftEncryptionAPI(address: address)
        let _ = encryptionAPI.createDevice(address: address, serverAddress: "https://www.simplesignal.co.uk")
        
        let uriValue2 = "https://www.simplesignal.co.uk/v1/devices/"
        self.stub(uri(uriValue2), http(204))
        
        let result = encryptionAPI.deleteDevice(serverAddress: "https://www.simplesignal.co.uk")
        
        switch result {
        case .success():
            let loadedRegistrationId = KeychainSwift().get("\(address.combinedValue)registrationId")
            XCTAssertNil(loadedRegistrationId)
            expectation.fulfill()
        case .failure(let error):
            print(error)
        }
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testDeleteMessage() throws {
        let expectation = XCTestExpectation(description: "Successfully delete a message")
        
        let uriValue = "https://www.simplesignal.co.uk/v1/device/"
        let data: NSDictionary = [
            "code": "device_created",
            "message": "Device successfully created"
        ]
        self.stub(uri(uriValue), json(data, status: 201))
        
        let name = "testRecipient"
        let deviceId = UInt32(1)
        let address = try ProtocolAddress(name: name, deviceId: UInt32(deviceId))
        let encryptionAPI = try SimpleSignalSwiftEncryptionAPI(address: address)
        let _ = encryptionAPI.createDevice(address: address, serverAddress: "https://www.simplesignal.co.uk")
        
        let registrationId = UInt32(KeychainSwift().get("\(address.combinedValue)registrationId")!)!
        
        let uriValue2 = "https://www.simplesignal.co.uk/v1/\(registrationId)/messages/"
        print(uriValue2)
        let data2: NSArray = [
            "message_deleted"
        ]
        self.stub(uri(uriValue2), json(data2, status: 200))
        
        let result = encryptionAPI.deleteMessage(serverAddress: "https://www.simplesignal.co.uk", messageIds: [1])
        
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
}
