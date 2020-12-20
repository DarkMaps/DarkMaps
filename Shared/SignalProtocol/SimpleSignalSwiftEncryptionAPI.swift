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
    var store: KeychainSignalProtocolStore
    
    init(combinedName: String) throws {
        self.keychainSwift = KeychainSwift(keyPrefix: combinedName)
        do {
            self.store = try KeychainSignalProtocolStore(keychainSwift: keychainSwift)
        } catch {
            do {
                try createDevice()
            } catch {
                throw SSAPIInitError.unableToCreateDevice
            }
        }
    }
    
    public func createDevice() throws {
            
        let identityKey = try IdentityKeyPair.generate()
        let deviceId = UInt32.random(in: 0...65535)
        
        self.store = try KeychainSignalProtocolStore.init(keychainSwift: keychainSwift, identity: identityKey, deviceId: deviceId)
        
        for i in 1...100 {
            let preKey = try PrivateKey.generate()
            try store.storePreKey(
                PreKeyRecord.init(id: UInt32(i), privateKey: preKey),
                id: UInt32(i),
                context: nil)
        }
        
        
        let signedPreKey = try PrivateKey.generate()
        let signedPrekeySignature = try identityKey.privateKey.generateSignature(
            message: signedPreKey.publicKey().serialize()
        )
        try store.storeSignedPreKey(
            SignedPreKeyRecord.init(
                id: 1,
                timestamp: Date().ticks,
                privateKey: signedPreKey,
                signature: signedPrekeySignature),
            id: 1,
            context: nil
        )
    }
    
}

extension Date {
    var ticks: UInt64 {
        return UInt64((self.timeIntervalSince1970 + 62_135_596_800) * 10_000_000)
    }
}
