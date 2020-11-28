//
//  KeychainSignalStore.swift
//  SignalMaps
//
//  Created by Matthew Roche on 21/11/2020.
//

import Foundation

public class KeychainSignalProtocolStore: IdentityKeyStore, PreKeyStore, SignedPreKeyStore, SessionStore, SenderKeyStore {
    
    private var keychainSwift: KeychainSwift

    public init(keychainSwift: KeychainSwift) throws {
        self.keychainSwift = keychainSwift
        let privateKey = try IdentityKeyPair.generate()
        let deviceId = UInt32.random(in: 0...65535)
        keychainSwift.set(Data(try privateKey.serialize()), forKey: "privateKey")
        keychainSwift.set(String(deviceId), forKey: "deviceId")
    }

    public init(keychainSwift: KeychainSwift, identity: IdentityKeyPair, deviceId: UInt32) throws {
        self.keychainSwift = keychainSwift
        keychainSwift.set(Data(try identity.serialize()), forKey: "privateKey")
        keychainSwift.set(String(deviceId), forKey: "deviceId")
    }

    public func identityKeyPair(context: UnsafeMutableRawPointer?) throws -> IdentityKeyPair {
        guard let identityKeyPairData = keychainSwift.getData("privateKey") else {
            throw KeychainSignalProtocolStoreError.noStoredIdentityKey
        }
        return try IdentityKeyPair.init(bytes: identityKeyPairData)
    }

    public func localRegistrationId(context: UnsafeMutableRawPointer?) throws -> UInt32 {
        guard let deviceIdString = keychainSwift.get("deviceId") else {
            throw KeychainSignalProtocolStoreError.noStoredDeviceId
        }
        guard let deviceId = UInt32(deviceIdString) else {
            throw KeychainSignalProtocolStoreError.noStoredDeviceId
        }
        return deviceId
    }

    public func saveIdentity(_ identity: IdentityKey, for address: ProtocolAddress, context: UnsafeMutableRawPointer?) throws -> Bool {
        let keyName = "publicKey:\(address)"
        let existingIdentity = keychainSwift.getData(keyName)
        keychainSwift.set(Data(try identity.serialize()), forKey: keyName)
        if existingIdentity == nil {
            return false; // newly created
        } else {
            return true
        }
    }

    public func isTrustedIdentity(_ identity: IdentityKey, for address: ProtocolAddress, direction: Direction, context: UnsafeMutableRawPointer?) throws -> Bool {
        let keyName = "publicKey:\(address)"
        guard let pkData = keychainSwift.getData(keyName) else {
            return true
        }
        return try IdentityKey(bytes: pkData) == identity
    }

    public func identity(for address: ProtocolAddress, context: UnsafeMutableRawPointer?) throws -> IdentityKey? {
        let keyName = "publicKey:\(address)"
        guard let pkData = keychainSwift.getData(keyName) else {
            return nil
        }
        return try IdentityKey(bytes: pkData)
    }

    public func loadPreKey(id: UInt32, context: UnsafeMutableRawPointer?) throws -> PreKeyRecord {
        let keyName = "preKey:\(id)"
        guard let pkData = keychainSwift.getData(keyName) else {
            throw SignalError.invalidKeyIdentifier("no prekey with this identifier")
        }
        return try PreKeyRecord(bytes: pkData)
    }

    public func storePreKey(_ record: PreKeyRecord, id: UInt32, context: UnsafeMutableRawPointer?) throws {
        let keyName = "preKey:\(id)"
        keychainSwift.set(Data(try record.serialize()), forKey: keyName)
    }

    public func removePreKey(id: UInt32, context: UnsafeMutableRawPointer?) throws {
        let keyName = "preKey:\(id)"
        keychainSwift.delete(keyName)
    }

    public func loadSignedPreKey(id: UInt32, context: UnsafeMutableRawPointer?) throws -> SignedPreKeyRecord {
        let keyName = "signedPreKey:\(id)"
        guard let spkData = keychainSwift.getData(keyName) else {
            throw SignalError.invalidKeyIdentifier("no signed prekey with this identifier")
        }
        return try SignedPreKeyRecord(bytes: spkData)
    }

    public func storeSignedPreKey(_ record: SignedPreKeyRecord, id: UInt32, context: UnsafeMutableRawPointer?) throws {
        let keyName = "signedPreKey:\(id)"
        keychainSwift.set(Data(try record.serialize()), forKey: keyName)
    }

    public func loadSession(for address: ProtocolAddress, context: UnsafeMutableRawPointer?) throws -> SessionRecord? {
        let keyName = "session:\(address.hashValue)"
        guard let sessionData = keychainSwift.getData(keyName) else {
            return nil
        }
        return try SessionRecord(bytes: sessionData)
    }

    public func storeSession(_ record: SessionRecord, for address: ProtocolAddress, context: UnsafeMutableRawPointer?) throws {
        let keyName = "session:\(address.hashValue)"
        keychainSwift.set(Data(try record.serialize()), forKey: keyName)
    }

    public func storeSenderKey(name: SenderKeyName, record: SenderKeyRecord, context: UnsafeMutableRawPointer?) throws {
        let keyName = "senderKey:\(name.hashValue)"
        keychainSwift.set(Data(try record.serialize()), forKey: keyName)
    }

    public func loadSenderKey(name: SenderKeyName, context: UnsafeMutableRawPointer?) throws -> SenderKeyRecord? {
        let keyName = "senderKey:\(name.hashValue)"
        guard let senderKeyData = keychainSwift.getData(keyName) else {
            return nil
        }
        return try SenderKeyRecord(bytes: senderKeyData)
    }
}


public enum KeychainSignalProtocolStoreError: Error {
    case noStoredIdentityKey
    case noStoredDeviceId
}
