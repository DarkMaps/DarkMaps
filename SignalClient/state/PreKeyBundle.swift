//
// Copyright 2020 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

import SignalFfi
import Foundation

public class PreKeyBundle {
    private var handle: OpaquePointer?

    deinit {
        signal_pre_key_bundle_destroy(handle)
    }

    internal var nativeHandle: OpaquePointer? {
        return handle
    }

    // with a prekey
    public init<Bytes: ContiguousBytes>(registrationId: UInt32,
                                        deviceId: UInt32,
                                        prekeyId: UInt32,
                                        prekey: PublicKey,
                                        signedPrekeyId: UInt32,
                                        signedPrekey: PublicKey,
                                        signedPrekeySignature: Bytes,
                                        identity identityKey: IdentityKey) throws {
        handle = try signedPrekeySignature.withUnsafeBytes {
            var prekeyId = prekeyId
            var result: OpaquePointer?
            try checkError(signal_pre_key_bundle_new(&result,
                                                     registrationId,
                                                     deviceId,
                                                     &prekeyId,
                                                     prekey.nativeHandle,
                                                     signedPrekeyId,
                                                     signedPrekey.nativeHandle,
                                                     $0.baseAddress?.assumingMemoryBound(to: UInt8.self),
                                                     $0.count,
                                                     identityKey.publicKey.nativeHandle))
            return result
        }
    }

    // without a prekey
    public init<Bytes: ContiguousBytes>(registrationId: UInt32,
                                        deviceId: UInt32,
                                        signedPrekeyId: UInt32,
                                        signedPrekey: PublicKey,
                                        signedPrekeySignature: Bytes,
                                        identity identityKey: IdentityKey) throws {
        handle = try signedPrekeySignature.withUnsafeBytes {
            var result: OpaquePointer?
            try checkError(signal_pre_key_bundle_new(&result,
                                                     registrationId,
                                                     deviceId,
                                                     nil,
                                                     nil,
                                                     signedPrekeyId,
                                                     signedPrekey.nativeHandle,
                                                     $0.baseAddress?.assumingMemoryBound(to: UInt8.self),
                                                     $0.count,
                                                     identityKey.publicKey.nativeHandle))
            return result
        }
    }

    public func registrationId() throws -> UInt32 {
        return try invokeFnReturningInteger {
            signal_pre_key_bundle_get_registration_id(handle, $0)
        }
    }

    public func deviceId() throws -> UInt32 {
        return try invokeFnReturningInteger {
            signal_pre_key_bundle_get_device_id(handle, $0)
        }
    }

    public func signedPreKeyId() throws -> UInt32 {
        return try invokeFnReturningInteger {
            signal_pre_key_bundle_get_signed_pre_key_id(handle, $0)
        }
    }

    public func preKeyId() throws -> UInt32? {
        let prekey_id = try invokeFnReturningInteger {
            signal_pre_key_bundle_get_signed_pre_key_id(handle, $0)
        }

        if prekey_id == 0xFFFFFFFF {
            return nil
        } else {
            return prekey_id
        }
    }

    public func preKeyPublic() throws -> PublicKey? {
        return try invokeFnReturningOptionalPublicKey {
            signal_pre_key_bundle_get_pre_key_public($0, handle)
        }
    }

    public func identityKey() throws -> IdentityKey {
        let pk = try invokeFnReturningPublicKey {
            signal_pre_key_bundle_get_identity_key($0, handle)
        }
        return IdentityKey(publicKey: pk)
    }

    public func signedPreKeyPublic() throws -> PublicKey {
        return try invokeFnReturningPublicKey {
            signal_pre_key_bundle_get_signed_pre_key_public($0, handle)
        }
    }

    public func signedPreKeySignature() throws -> [UInt8] {
        return try invokeFnReturningArray {
            signal_pre_key_bundle_get_signed_pre_key_signature(handle, $0, $1)
        }
    }
}
