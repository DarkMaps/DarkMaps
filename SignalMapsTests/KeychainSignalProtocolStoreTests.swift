//
//  KeychainSignalProtocolStoreTests.swift
//  SignalMapsTests
//
//  Created by Matthew Roche on 20/12/2020.
//

import XCTest

@testable import SignalMaps

class KeychainSignalProtocolStoreTests: XCTestCase {
    
    let keychainSwift = KeychainSwift(keyPrefix: "testPrefix")

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        keychainSwift.clear()
    }

    func testInitWithNewDetails() throws {
        let identityKey = try IdentityKeyPair.generate()
        let deviceId = UInt32.random(in: 0...65535)
        
        let store = try KeychainSignalProtocolStore.init(keychainSwift: keychainSwift, identity: identityKey, deviceId: deviceId)
        
        XCTAssertNotNil(store.identityKeyPair)
        XCTAssertNotNil(store.localRegistrationId)
    }
    
    func testInitWithExistingDetails() throws {
        let identityKey = try IdentityKeyPair.generate()
        let deviceId = UInt32.random(in: 0...65535)
        
        keychainSwift.set(Data(try identityKey.serialize()), forKey: "privateKey")
        keychainSwift.set(String(deviceId), forKey: "deviceId")
        
        let store = try KeychainSignalProtocolStore.init(keychainSwift: keychainSwift)
        
        XCTAssertNotNil(store.identityKeyPair)
        XCTAssertNotNil(store.localRegistrationId)
    }
    
    func testInitFailsIfExisitingDetailsAndNewProvided() throws {
        var thrownError: Error?
        
        let identityKey = try IdentityKeyPair.generate()
        let deviceId = UInt32.random(in: 0...65535)
        
        keychainSwift.set(Data(try identityKey.serialize()), forKey: "privateKey")
        keychainSwift.set(String(deviceId), forKey: "deviceId")
        
        XCTAssertThrowsError(try KeychainSignalProtocolStore.init(keychainSwift: keychainSwift, identity: identityKey, deviceId: deviceId)) {
            thrownError = $0
        }
        XCTAssertEqual(thrownError as? KeychainSignalProtocolStoreError, KeychainSignalProtocolStoreError.identityKeyAlreadyExists)
    }
    
    func testInitFailsIfNoStoresDetailsAndNoneProvided() throws {
        var thrownError: Error?
        
        XCTAssertThrowsError(try KeychainSignalProtocolStore.init(keychainSwift: keychainSwift)) {
            thrownError = $0
        }
        XCTAssertEqual(thrownError as? KeychainSignalProtocolStoreError, KeychainSignalProtocolStoreError.noStoredIdentityKey)
    }
    
    func testLoadIdentityKey() throws {
        let identityKey = try IdentityKeyPair.generate()
        let deviceId = UInt32.random(in: 0...65535)
        let store = try KeychainSignalProtocolStore.init(keychainSwift: keychainSwift, identity: identityKey, deviceId: deviceId)
        let loadedKey = try store.identityKeyPair(context: nil)
        XCTAssertEqual(loadedKey.publicKey, identityKey.publicKey)
    }
    
    func testLoadIdentityKeyFailsIfNotPresent() throws {
        var thrownError: Error?
        let identityKey = try IdentityKeyPair.generate()
        let deviceId = UInt32.random(in: 0...65535)
        let store = try KeychainSignalProtocolStore.init(keychainSwift: keychainSwift, identity: identityKey, deviceId: deviceId)
        keychainSwift.delete("privateKey")
        XCTAssertThrowsError(try store.identityKeyPair(context: nil)) {
            thrownError = $0
        }
        XCTAssertEqual(thrownError as? KeychainSignalProtocolStoreError, KeychainSignalProtocolStoreError.noStoredIdentityKey)
    }
    
    func testLoadRegistrationID() throws {
        let identityKey = try IdentityKeyPair.generate()
        let deviceId = UInt32.random(in: 0...65535)
        let store = try KeychainSignalProtocolStore.init(keychainSwift: keychainSwift, identity: identityKey, deviceId: deviceId)
        let loadedId = try store.localRegistrationId(context: nil)
        XCTAssertEqual(deviceId, loadedId)
    }
    
    func testLoadRegistrationIDFailsIfNotPresent() throws {
        var thrownError: Error?
        let identityKey = try IdentityKeyPair.generate()
        let deviceId = UInt32.random(in: 0...65535)
        let store = try KeychainSignalProtocolStore.init(keychainSwift: keychainSwift, identity: identityKey, deviceId: deviceId)
        keychainSwift.delete("deviceId")
        XCTAssertThrowsError(try store.localRegistrationId(context: nil)) {
            thrownError = $0
        }
        XCTAssertEqual(thrownError as? KeychainSignalProtocolStoreError, KeychainSignalProtocolStoreError.noStoredDeviceId)
    }
    
    func testLoadRegistrationIDFailsIfNotInteger() throws {
        var thrownError: Error?
        let identityKey = try IdentityKeyPair.generate()
        let deviceId = UInt32.random(in: 0...65535)
        let store = try KeychainSignalProtocolStore.init(keychainSwift: keychainSwift, identity: identityKey, deviceId: deviceId)
        keychainSwift.set("jhdsgjs", forKey: "deviceId")
        XCTAssertThrowsError(try store.localRegistrationId(context: nil)) {
            thrownError = $0
        }
        XCTAssertEqual(thrownError as? KeychainSignalProtocolStoreError, KeychainSignalProtocolStoreError.noStoredDeviceId)
    }
    
    func testSaveIdentity() throws {
        let identityKey = try IdentityKeyPair.generate()
        let deviceId = UInt32.random(in: 0...65535)
        let store = try KeychainSignalProtocolStore.init(keychainSwift: keychainSwift, identity: identityKey, deviceId: deviceId)
        
        let address = try ProtocolAddress(name: "testName", deviceId: 1234)
        let key = try IdentityKeyPair.generate().identityKey
        let boolOutcome = try store.saveIdentity(key, for: address, context: nil)
        
        XCTAssertEqual(boolOutcome, false)
    }
    
    func testSaveIdentityReturnsTrueIfExisting() throws {
        let identityKey = try IdentityKeyPair.generate()
        let deviceId = UInt32.random(in: 0...65535)
        let store = try KeychainSignalProtocolStore.init(keychainSwift: keychainSwift, identity: identityKey, deviceId: deviceId)
        
        let address = try ProtocolAddress(name: "testName", deviceId: 1234)
        var key = try IdentityKeyPair.generate().identityKey
        let _ = try store.saveIdentity(key, for: address, context: nil)
        key = try IdentityKeyPair.generate().identityKey
        let boolOutcome = try store.saveIdentity(key, for: address, context: nil)
        
        XCTAssertEqual(boolOutcome, true)
    }
    
    func testIsTrustedIdentityTrueIfMatchiing() throws {
        let identityKey = try IdentityKeyPair.generate()
        let deviceId = UInt32.random(in: 0...65535)
        let store = try KeychainSignalProtocolStore.init(keychainSwift: keychainSwift, identity: identityKey, deviceId: deviceId)
        
        let address = try ProtocolAddress(name: "testName", deviceId: 1234)
        let key = try IdentityKeyPair.generate().identityKey
        let _ = try store.saveIdentity(key, for: address, context: nil)
        
        let boolOutcome = try store.isTrustedIdentity(key, for: address, direction: Direction.receiving, context: nil)
        
        XCTAssertEqual(boolOutcome, true)
    }
    
    func testIsTrustedIdentityFalseIfNotMatching() throws {
        let identityKey = try IdentityKeyPair.generate()
        let deviceId = UInt32.random(in: 0...65535)
        let store = try KeychainSignalProtocolStore.init(keychainSwift: keychainSwift, identity: identityKey, deviceId: deviceId)
        
        let address = try ProtocolAddress(name: "testName", deviceId: 1234)
        var key = try IdentityKeyPair.generate().identityKey
        let _ = try store.saveIdentity(key, for: address, context: nil)
        
        key = try IdentityKeyPair.generate().identityKey
        let boolOutcome = try store.isTrustedIdentity(key, for: address, direction: Direction.receiving, context: nil)
        
        XCTAssertEqual(boolOutcome, false)
    }
    
    func testLoadIdentity() throws {
        let identityKey = try IdentityKeyPair.generate()
        let deviceId = UInt32.random(in: 0...65535)
        let store = try KeychainSignalProtocolStore.init(keychainSwift: keychainSwift, identity: identityKey, deviceId: deviceId)
        
        let address = try ProtocolAddress(name: "testName", deviceId: 1234)
        let key = try IdentityKeyPair.generate().identityKey
        let _ = try store.saveIdentity(key, for: address, context: nil)
        
        let loadedKey = try store.identity(for: address, context: nil)
        
        XCTAssertEqual(loadedKey, key)
    }
    
    func testLoadIdentityNilIfNonePresent() throws {
        let identityKey = try IdentityKeyPair.generate()
        let deviceId = UInt32.random(in: 0...65535)
        let store = try KeychainSignalProtocolStore.init(keychainSwift: keychainSwift, identity: identityKey, deviceId: deviceId)
        
        let address = try ProtocolAddress(name: "testName", deviceId: 1234)
        
        let loadedKey = try store.identity(for: address, context: nil)
        
        XCTAssertEqual(loadedKey, nil)
    }
    
    func testLoadStoreAndRemovePreKey() throws {
        let identityKey = try IdentityKeyPair.generate()
        let deviceId = UInt32.random(in: 0...65535)
        let store = try KeychainSignalProtocolStore.init(keychainSwift: keychainSwift, identity: identityKey, deviceId: deviceId)
        
        let preKey = try PreKeyRecord.init(id: 1, privateKey: try PrivateKey.generate())
        try store.storePreKey(preKey, id: 1, context: nil)
        var loadedKeyData = keychainSwift.getData("preKey:1")
        XCTAssertEqual(loadedKeyData, Data(try preKey.serialize()))
        
        let loadedKey = try store.loadPreKey(id: 1, context: nil)
        XCTAssertEqual(try loadedKey.serialize(), try preKey.serialize())
        
        try store.removePreKey(id: 1, context: nil)
        loadedKeyData = keychainSwift.getData("preKey:1")
        XCTAssertEqual(loadedKeyData, nil)
        
        XCTAssertThrowsError(try store.loadPreKey(id: 1, context: nil))
    }
    
    func testLoadAndStoreSignedPreKey() throws {
        let identityKey = try IdentityKeyPair.generate()
        let deviceId = UInt32.random(in: 0...65535)
        let store = try KeychainSignalProtocolStore.init(keychainSwift: keychainSwift, identity: identityKey, deviceId: deviceId)
        
        let signedPreKey = try PrivateKey.generate()
        let signedPrekeySignature = try identityKey.privateKey.generateSignature(message: signedPreKey.publicKey().serialize())
        let signedPreKeyRecord = try SignedPreKeyRecord.init(
            id: 1,
            timestamp: Date().ticks,
            privateKey: signedPreKey,
            signature: signedPrekeySignature)
        try store.storeSignedPreKey(signedPreKeyRecord, id: 1, context: nil)
        let loadedKeyData = keychainSwift.getData("signedPreKey:1")
        XCTAssertEqual(loadedKeyData, Data(try signedPreKeyRecord.serialize()))
        
        let loadedKey = try store.loadSignedPreKey(id: 1, context: nil)
        XCTAssertEqual(try loadedKey.serialize(), try signedPreKeyRecord.serialize())
        
        keychainSwift.delete("signedPreKey:1")
        
        XCTAssertThrowsError(try store.loadSignedPreKey(id: 1, context: nil))
    }

}

