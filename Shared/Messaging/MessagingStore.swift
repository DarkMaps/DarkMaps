//
//  MessagingStore.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 25/12/2020.
//

import Foundation

public class MessagingStore {
    
    private var keychainSwift: KeychainSwift

    public init(localAddress: ProtocolAddress) {
        self.keychainSwift = KeychainSwift(keyPrefix: localAddress.combinedValue)
    }
    
    public func clearAllData() {
        let keys = keychainSwift.allKeys
        for key in keys {
            if key.starts(with: "\(keychainSwift.keyPrefix)-msg-") {
                let keyToDelete = key.replacingOccurrences(of: keychainSwift.keyPrefix, with: "")
                keychainSwift.delete(keyToDelete)
            }
        }
    }

    public func loadMessage(sender: ProtocolAddress) throws -> LocationMessage {
        let keyName = "-msg-\(sender.combinedValue)"
        guard let messageData = keychainSwift.getData(keyName) else {
            throw MessageStoreError.noMessageFromThisSender
        }
        let decoder = JSONDecoder()
        guard let decodedResponse = try? decoder.decode(LocationMessage.self, from: messageData) else {
            keychainSwift.delete(keyName)
            throw MessageStoreError.poorlyFormattedMessageData
        }
        return decodedResponse
    }

    public func storeMessage(_ message: LocationMessage) throws {
        let keyName = "-msg-\(message.sender.combinedValue)"
        let jsonEncoder = JSONEncoder()
        let jsonData = try jsonEncoder.encode(message)
        keychainSwift.set(jsonData, forKey: keyName)
    }

    public func removeMessage(sender: ProtocolAddress) throws {
        let keyName = "-msg-\(sender.combinedValue)"
        keychainSwift.delete(keyName)
    }
    
    public func getMessageSummary() throws -> [ShortLocationMessage] {
        var summaryMessageArray: [ShortLocationMessage] = []
        let keys = keychainSwift.allKeys
        for key in keys {
            if key.starts(with: "\(keychainSwift.keyPrefix)-msg-") {
                let keyToGet = key.replacingOccurrences(of: keychainSwift.keyPrefix, with: "")
                guard let messageData = keychainSwift.getData(keyToGet) else {
                    throw MessageStoreError.noMessageFromThisSender
                }
                let decoder = JSONDecoder()
                guard let decodedResponse = try? decoder.decode(LocationMessage.self, from: messageData) else {
                    keychainSwift.delete(keyToGet)
                    throw MessageStoreError.poorlyFormattedMessageData
                }
                summaryMessageArray.append(ShortLocationMessage(decodedResponse))
            }
        }
        summaryMessageArray.sort { (first, second) -> Bool in
            first.lastReceived > second.lastReceived
        }
        return summaryMessageArray
    }
    
    public func storeLiveMessageRecipient(_ recipient: ProtocolAddress) throws {
        let keyName = "-msg-liveMessageRecipients"
        var arrayToAppend: [String] = []
        if let arrayData = keychainSwift.getData(keyName) {
            let decoder = JSONDecoder()
            guard let decodedResponse = try? decoder.decode([String].self, from: arrayData) else {
                print("Error decoding LiveMessageArrayData")
                keychainSwift.delete(keyName)
                throw MessageStoreError.poorlyFormattedLiveMessageArrayData
            }
            arrayToAppend = decodedResponse
        }
        let stringToAppend = recipient.combinedValue
        if let _ = arrayToAppend.firstIndex(of: stringToAppend) {
            throw MessageStoreError.liveMessageRecipientAlreadyExists
        } else {
            arrayToAppend.append(stringToAppend)
        }
        let encoder = JSONEncoder()
        let encodedArrayData = try! encoder.encode(arrayToAppend)
        keychainSwift.set(encodedArrayData, forKey: keyName)
    }
    
    public func getLiveMessageRecipients() throws -> [ProtocolAddress] {
        let keyName = "-msg-liveMessageRecipients"
        guard let arrayData = keychainSwift.getData(keyName) else {
            return []
        }
        let decoder = JSONDecoder()
        guard let decodedResponse = try? decoder.decode([String].self, from: arrayData) else {
            print("Error decoding LiveMessageArrayData")
            keychainSwift.delete(keyName)
            throw MessageStoreError.poorlyFormattedLiveMessageArrayData
        }
        var arrayToReturn: [ProtocolAddress] = []
        for recipientCombinedName in decodedResponse {
            guard let address = try? ProtocolAddress(recipientCombinedName) else {
                print("Error decoding LiveMessageArrayData")
                keychainSwift.delete(keyName)
                throw MessageStoreError.poorlyFormattedLiveMessageArrayData
            }
            arrayToReturn.append(address)
        }
        return arrayToReturn
    }
    
    public func removeLiveMessageRecipient(_ recipient: ProtocolAddress) throws {
        let keyName = "-msg-liveMessageRecipients"
        var arrayToDeleteFrom: [String] = []
        if let arrayData = keychainSwift.getData(keyName) {
            let decoder = JSONDecoder()
            guard let decodedResponse = try? decoder.decode([String].self, from: arrayData) else {
                print("Error decoding LiveMessageArrayData")
                keychainSwift.delete(keyName)
                throw MessageStoreError.poorlyFormattedLiveMessageArrayData
            }
            arrayToDeleteFrom = decodedResponse
        }
        print(arrayToDeleteFrom)
        let stringToDelete = recipient.combinedValue
        print(stringToDelete)
        arrayToDeleteFrom.removeAll { element in
            element == stringToDelete
        }
        print(arrayToDeleteFrom)
        let encoder = JSONEncoder()
        let encodedArrayData = try! encoder.encode(arrayToDeleteFrom)
        keychainSwift.set(encodedArrayData, forKey: keyName)
    }
    
}
