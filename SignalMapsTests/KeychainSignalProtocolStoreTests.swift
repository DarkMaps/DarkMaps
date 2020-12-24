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
        let address = try ProtocolAddress(name: "test", deviceId: 1)
        let identityKey = try IdentityKeyPair.generate()
        let registrationId = UInt32.random(in: 0...65535)
        
        let store = try KeychainSignalProtocolStore.init(keychainSwift: keychainSwift, address: address, identity: identityKey, registrationId: registrationId)
        
        XCTAssertNotNil(store.identityKeyPair)
        XCTAssertNotNil(store.localRegistrationId)
    }
    
    func testInitWithExistingDetails() throws {
        let address = try ProtocolAddress(name: "test", deviceId: 1)
        let identityKey = try IdentityKeyPair.generate()
        let registrationId = UInt32.random(in: 0...65535)
        
        keychainSwift.set(address.combinedValue, forKey: "address")
        keychainSwift.set(Data(try identityKey.serialize()), forKey: "privateKey")
        keychainSwift.set(String(registrationId), forKey: "registrationId")
        
        let store = try KeychainSignalProtocolStore.init(keychainSwift: keychainSwift)
        
        XCTAssertNotNil(store.identityKeyPair)
        XCTAssertNotNil(store.localRegistrationId)
    }
    
    func testInitFailsIfExisitingDetailsAndNewProvided() throws {
        var thrownError: Error?
        
        let address = try ProtocolAddress(name: "test", deviceId: 1)
        let identityKey = try IdentityKeyPair.generate()
        let registrationId = UInt32.random(in: 0...65535)
        
        keychainSwift.set(address.combinedValue, forKey: "address")
        keychainSwift.set(Data(try identityKey.serialize()), forKey: "privateKey")
        keychainSwift.set(String(registrationId), forKey: "registrationId")
        
        XCTAssertThrowsError(try KeychainSignalProtocolStore.init(keychainSwift: keychainSwift, address: address, identity: identityKey, registrationId: registrationId)) {
            thrownError = $0
        }
        XCTAssertEqual(thrownError as? KeychainSignalProtocolStoreError, KeychainSignalProtocolStoreError.addressAlreadyExists)
    }
    
    func testInitFailsIfNoStoresDetailsAndNoneProvided() throws {
        var thrownError: Error?
        
        XCTAssertThrowsError(try KeychainSignalProtocolStore.init(keychainSwift: keychainSwift)) {
            thrownError = $0
        }
        XCTAssertEqual(thrownError as? KeychainSignalProtocolStoreError, KeychainSignalProtocolStoreError.noStoredAddress)
    }
    
    func testLoadIdentityKey() throws {
        let address = try ProtocolAddress(name: "test", deviceId: 1)
        let identityKey = try IdentityKeyPair.generate()
        let registrationId = UInt32.random(in: 0...65535)
        let store = try KeychainSignalProtocolStore.init(keychainSwift: keychainSwift, address: address, identity: identityKey, registrationId: registrationId)
        let loadedKey = try store.identityKeyPair(context: nil)
        XCTAssertEqual(loadedKey.publicKey, identityKey.publicKey)
    }
    
    func testLoadIdentityKeyFailsIfNotPresent() throws {
        var thrownError: Error?
        let address = try ProtocolAddress(name: "test", deviceId: 1)
        let identityKey = try IdentityKeyPair.generate()
        let registrationId = UInt32.random(in: 0...65535)
        let store = try KeychainSignalProtocolStore.init(keychainSwift: keychainSwift, address: address, identity: identityKey, registrationId: registrationId)
        keychainSwift.delete("privateKey")
        XCTAssertThrowsError(try store.identityKeyPair(context: nil)) {
            thrownError = $0
        }
        XCTAssertEqual(thrownError as? KeychainSignalProtocolStoreError, KeychainSignalProtocolStoreError.noStoredIdentityKey)
    }
    
    func testLoadRegistrationID() throws {
        let address = try ProtocolAddress(name: "test", deviceId: 1)
        let identityKey = try IdentityKeyPair.generate()
        let registrationId = UInt32.random(in: 0...65535)
        let store = try KeychainSignalProtocolStore.init(keychainSwift: keychainSwift, address: address, identity: identityKey, registrationId: registrationId)
        let loadedId = try store.localRegistrationId(context: nil)
        XCTAssertEqual(registrationId, loadedId)
    }
    
    func testLoadRegistrationIDFailsIfNotPresent() throws {
        var thrownError: Error?
        let address = try ProtocolAddress(name: "test", deviceId: 1)
        let identityKey = try IdentityKeyPair.generate()
        let registrationId = UInt32.random(in: 0...65535)
        let store = try KeychainSignalProtocolStore.init(keychainSwift: keychainSwift, address: address, identity: identityKey, registrationId: registrationId)
        keychainSwift.delete("registrationId")
        XCTAssertThrowsError(try store.localRegistrationId(context: nil)) {
            thrownError = $0
        }
        XCTAssertEqual(thrownError as? KeychainSignalProtocolStoreError, KeychainSignalProtocolStoreError.noStoredRegistrationId)
    }
    
    func testLoadRegistrationIDFailsIfNotInteger() throws {
        var thrownError: Error?
        let address = try ProtocolAddress(name: "test", deviceId: 1)
        let identityKey = try IdentityKeyPair.generate()
        let registrationId = UInt32.random(in: 0...65535)
        let store = try KeychainSignalProtocolStore.init(keychainSwift: keychainSwift, address: address, identity: identityKey, registrationId: registrationId)
        keychainSwift.set("jhdsgjs", forKey: "registrationId")
        XCTAssertThrowsError(try store.localRegistrationId(context: nil)) {
            thrownError = $0
        }
        XCTAssertEqual(thrownError as? KeychainSignalProtocolStoreError, KeychainSignalProtocolStoreError.noStoredRegistrationId)
    }
    
    func testSaveIdentity() throws {
        let address = try ProtocolAddress(name: "test", deviceId: 1)
        let identityKey = try IdentityKeyPair.generate()
        let registrationId = UInt32.random(in: 0...65535)
        let store = try KeychainSignalProtocolStore.init(keychainSwift: keychainSwift, address: address, identity: identityKey, registrationId: registrationId)
        
        let key = try IdentityKeyPair.generate().identityKey
        let boolOutcome = try store.saveIdentity(key, for: address, context: nil)
        
        XCTAssertEqual(boolOutcome, false)
    }
    
    func testSaveIdentityReturnsTrueIfExisting() throws {
        let address = try ProtocolAddress(name: "test", deviceId: 1)
        let identityKey = try IdentityKeyPair.generate()
        let registrationId = UInt32.random(in: 0...65535)
        let store = try KeychainSignalProtocolStore.init(keychainSwift: keychainSwift, address: address, identity: identityKey, registrationId: registrationId)
        
        var key = try IdentityKeyPair.generate().identityKey
        let _ = try store.saveIdentity(key, for: address, context: nil)
        key = try IdentityKeyPair.generate().identityKey
        let boolOutcome = try store.saveIdentity(key, for: address, context: nil)
        
        XCTAssertEqual(boolOutcome, true)
    }
    
    func testIsTrustedIdentityTrueIfMatchiing() throws {
        let address = try ProtocolAddress(name: "test", deviceId: 1)
        let identityKey = try IdentityKeyPair.generate()
        let registrationId = UInt32.random(in: 0...65535)
        let store = try KeychainSignalProtocolStore.init(keychainSwift: keychainSwift, address: address, identity: identityKey, registrationId: registrationId)
        
        let key = try IdentityKeyPair.generate().identityKey
        let _ = try store.saveIdentity(key, for: address, context: nil)
        
        let boolOutcome = try store.isTrustedIdentity(key, for: address, direction: Direction.receiving, context: nil)
        
        XCTAssertEqual(boolOutcome, true)
    }
    
    func testIsTrustedIdentityFalseIfNotMatching() throws {
        let address = try ProtocolAddress(name: "test", deviceId: 1)
        let identityKey = try IdentityKeyPair.generate()
        let registrationId = UInt32.random(in: 0...65535)
        let store = try KeychainSignalProtocolStore.init(keychainSwift: keychainSwift, address: address, identity: identityKey, registrationId: registrationId)
        
        var key = try IdentityKeyPair.generate().identityKey
        let _ = try store.saveIdentity(key, for: address, context: nil)
        
        key = try IdentityKeyPair.generate().identityKey
        let boolOutcome = try store.isTrustedIdentity(key, for: address, direction: Direction.receiving, context: nil)
        
        XCTAssertEqual(boolOutcome, false)
    }
    
    func testLoadIdentity() throws {
        let address = try ProtocolAddress(name: "test", deviceId: 1)
        let identityKey = try IdentityKeyPair.generate()
        let registrationId = UInt32.random(in: 0...65535)
        let store = try KeychainSignalProtocolStore.init(keychainSwift: keychainSwift, address: address, identity: identityKey, registrationId: registrationId)
        
        let key = try IdentityKeyPair.generate().identityKey
        let _ = try store.saveIdentity(key, for: address, context: nil)
        
        let loadedKey = try store.identity(for: address, context: nil)
        
        XCTAssertEqual(loadedKey, key)
    }
    
    func testLoadIdentityNilIfNonePresent() throws {
        let address = try ProtocolAddress(name: "test", deviceId: 1)
        let identityKey = try IdentityKeyPair.generate()
        let registrationId = UInt32.random(in: 0...65535)
        let store = try KeychainSignalProtocolStore.init(keychainSwift: keychainSwift, address: address, identity: identityKey, registrationId: registrationId)
        
        let loadedKey = try store.identity(for: address, context: nil)
        
        XCTAssertEqual(loadedKey, nil)
    }
    
    func testLoadStoreAndRemovePreKey() throws {
        let address = try ProtocolAddress(name: "test", deviceId: 1)
        let identityKey = try IdentityKeyPair.generate()
        let registrationId = UInt32.random(in: 0...65535)
        let store = try KeychainSignalProtocolStore.init(keychainSwift: keychainSwift, address: address, identity: identityKey, registrationId: registrationId)
        
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
    
    func testCountPrekeys() throws {
        let address = try ProtocolAddress(name: "test", deviceId: 1)
        let identityKey = try IdentityKeyPair.generate()
        let registrationId = UInt32.random(in: 0...65535)
        let store = try KeychainSignalProtocolStore.init(keychainSwift: keychainSwift, address: address, identity: identityKey, registrationId: registrationId)
        
        let preKey = try PreKeyRecord.init(id: 1, privateKey: try PrivateKey.generate())
        keychainSwift.set(Data(try preKey.serialize()), forKey: "preKey:1")
        
        let preKey2 = try PreKeyRecord.init(id: 1, privateKey: try PrivateKey.generate())
        keychainSwift.set(Data(try preKey2.serialize()), forKey: "preKey:2")
        
        let (count, maxKeyId) = try store.countPreKeys()
        
        XCTAssertEqual(count, 2)
        XCTAssertEqual(maxKeyId, 2)
        
        keychainSwift.delete("preKey:1")
        
        let (count2, maxKeyId2) = try store.countPreKeys()
        
        XCTAssertEqual(count2, 1)
        XCTAssertEqual(maxKeyId2, 2)
    }
    
    func testLoadAndStoreSignedPreKey() throws {
        let address = try ProtocolAddress(name: "test", deviceId: 1)
        let identityKey = try IdentityKeyPair.generate()
        let registrationId = UInt32.random(in: 0...65535)
        let store = try KeychainSignalProtocolStore.init(keychainSwift: keychainSwift, address: address, identity: identityKey, registrationId: registrationId)
        
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
    
    func testSignedPreKeyDate() throws {
        let address = try ProtocolAddress(name: "test", deviceId: 1)
        let identityKey = try IdentityKeyPair.generate()
        let registrationId = UInt32.random(in: 0...65535)
        let store = try KeychainSignalProtocolStore.init(keychainSwift: keychainSwift, address: address, identity: identityKey, registrationId: registrationId)
        
        let signedPreKey = try PrivateKey.generate()
        let signedPrekeySignature = try identityKey.privateKey.generateSignature(message: signedPreKey.publicKey().serialize())
        let signedPreKeyRecord = try SignedPreKeyRecord.init(
            id: 1,
            timestamp: Date().ticks,
            privateKey: signedPreKey,
            signature: signedPrekeySignature)
        keychainSwift.set(Data(try signedPreKeyRecord.serialize()), forKey: "signedPreKey:1")
        
        let (_, maxKeyId) = try store.signedPreKeyAge()
        
        XCTAssertEqual(maxKeyId, 1)
        
        let signedPreKey2 = try PrivateKey.generate()
        let signedPrekeySignature2 = try identityKey.privateKey.generateSignature(message: signedPreKey.publicKey().serialize())
        let signedPreKeyRecord2 = try SignedPreKeyRecord.init(
            id: 2,
            timestamp: Date().ticks,
            privateKey: signedPreKey2,
            signature: signedPrekeySignature2)
        keychainSwift.set(Data(try signedPreKeyRecord2.serialize()), forKey: "signedPreKey:2")
        
        let (_, maxKeyId2) = try store.signedPreKeyAge()
        
        XCTAssertEqual(maxKeyId2, 2)
    }

}

