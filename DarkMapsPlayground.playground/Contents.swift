import DarkMapsiOSFramework
import Foundation

var str = "Hello, playground"

// **
// **
// **
// ** REMEMBER TO BUILD FRAMEWORK BEFORE RUNNING PLAYGROUND
// **
// **
// **

// Set up Alice
let aliceAddress = try ProtocolAddress.init(name: "Alice", deviceId: 1)
let aliceIdentityKey = try IdentityKeyPair.generate()
let aliceInMemoryStore = InMemorySignalProtocolStore.init(
    identity: aliceIdentityKey,
    deviceId: 1)
let alicePreKey = try PrivateKey.generate()
let aliceSignedPreKey = try PrivateKey.generate()
let aliceSignedPrekeySignature = try aliceIdentityKey.privateKey.generateSignature(message: aliceSignedPreKey.publicKey().serialize())
try aliceInMemoryStore.saveIdentity(
    aliceIdentityKey.identityKey,
    for: aliceAddress,
    context: nil)
try aliceInMemoryStore.storePreKey(
    PreKeyRecord.init(id: 1, privateKey: alicePreKey),
    id: 1,
    context: nil)
try aliceInMemoryStore.storeSignedPreKey(
    SignedPreKeyRecord.init(
        id: 1,
        timestamp: Date().ticks,
        privateKey: aliceSignedPreKey,
        signature: aliceSignedPrekeySignature),
    id: 1,
    context: nil)

// Create preKeyBundle
let alicePreKeyBundle = try PreKeyBundle.init(
    registrationId: 1234,
    deviceId: 1,
    prekeyId: 1,
    prekey: alicePreKey.publicKey(),
    signedPrekeyId: 1,
    signedPrekey: try aliceSignedPreKey.publicKey(),
    signedPrekeySignature: aliceSignedPrekeySignature,
    identity: aliceIdentityKey.identityKey)

// Set Up Bob
let bobAddress = try ProtocolAddress.init(name: "Bob", deviceId: 1)
let bobIdentityKey = try IdentityKeyPair.generate()
let bobInMemoryStore = InMemorySignalProtocolStore.init(
    identity: bobIdentityKey,
    deviceId: 1)

// Bob processes preKeyBundle
try processPreKeyBundle(
    alicePreKeyBundle,
    for: aliceAddress,
    sessionStore: bobInMemoryStore,
    identityStore: bobInMemoryStore,
    context: nil)

// Bob performs Encryption
let cipherText = try signalEncrypt(
    message: "A message".data(using: .utf8)!,
    for: aliceAddress,
    sessionStore: bobInMemoryStore,
    identityStore: bobInMemoryStore,
    context: nil)

// Bob creates Message
let message = try! PreKeySignalMessage(bytes: try! cipherText.serialize())

// Alice decrypts message
let decryptedMessageData = try signalDecryptPreKey(
    message: message,
    from: bobAddress,
    sessionStore: aliceInMemoryStore,
    identityStore: aliceInMemoryStore,
    preKeyStore: aliceInMemoryStore,
    signedPreKeyStore: aliceInMemoryStore,
    context: nil)

let decryptedMessageString = String(decoding: decryptedMessageData, as: UTF8.self)

print("Decrypted message: \(decryptedMessageString)")

// Alice sends message back to Bob
let bobCipherText = try signalEncrypt(
    message: "A second message".data(using: .utf8)!,
    for: bobAddress,
    sessionStore: aliceInMemoryStore,
    identityStore: aliceInMemoryStore,
    context: nil)
let bobMessage = try! SignalMessage(bytes: try! bobCipherText.serialize())

// Bob decrypts the message
let secondDecryptedMessageData = try signalDecrypt(
    message: bobMessage,
    from: aliceAddress,
    sessionStore: bobInMemoryStore,
    identityStore: bobInMemoryStore,
    context: nil)

let secondDecryptedMessageString = String(decoding: secondDecryptedMessageData, as: UTF8.self)

print("Second decrypted message: \(secondDecryptedMessageString)")

// MARK: Testing out-of-order messages

// Alice sends two messages
let bobFirstOOOCipherText = try signalEncrypt(
    message: "First message".data(using: .utf8)!,
    for: bobAddress,
    sessionStore: aliceInMemoryStore,
    identityStore: aliceInMemoryStore,
    context: nil)
let bobFirstOOOMessage = try! SignalMessage(bytes: try! bobFirstOOOCipherText.serialize())
let bobSecondOOOCipherText = try signalEncrypt(
    message: "Second message".data(using: .utf8)!,
    for: bobAddress,
    sessionStore: aliceInMemoryStore,
    identityStore: aliceInMemoryStore,
    context: nil)
let bobSecondOOOMessage = try! SignalMessage(bytes: try! bobSecondOOOCipherText.serialize())

// Bob decrypts the second message
let secondDecryptedOOOMessageData = try signalDecrypt(
    message: bobSecondOOOMessage,
    from: aliceAddress,
    sessionStore: bobInMemoryStore,
    identityStore: bobInMemoryStore,
    context: nil)

let secondOOODecryptedMessageString = String(decoding: secondDecryptedMessageData, as: UTF8.self)

// Then decrypts the first message
let firstDecryptedOOOMessageData = try signalDecrypt(
    message: bobFirstOOOMessage,
    from: aliceAddress,
    sessionStore: bobInMemoryStore,
    identityStore: bobInMemoryStore,
    context: nil)

let firstOOODecryptedMessageString = String(decoding: secondDecryptedMessageData, as: UTF8.self)



extension Date {
    var ticks: UInt64 {
        return UInt64((self.timeIntervalSince1970 + 62_135_596_800) * 10_000_000)
    }
}
