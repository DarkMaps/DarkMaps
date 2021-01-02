//
//  MessagingStore.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 25/12/2020.
//

import Foundation

public class MessagingStore {
    
    private let keychainSwift: KeychainSwift
    private let notificationCentre = NotificationCenter.default

    public init(localAddress: ProtocolAddress) {
        self.keychainSwift = KeychainSwift(keyPrefix: localAddress.combinedValue)
    }
    
    private func sendNotification(count: Int) {
        notificationCentre.post(name: .messagingStore_LiveMessagesUpdates, object: nil, userInfo: ["count": count])
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
                var keyToGet: String
                // Removing only first occurence of prefix so can send location to self
                if let range = key.range(of: keychainSwift.keyPrefix){
                    keyToGet = key.replacingCharacters(in: range, with: "")
                } else {
                    keyToGet = key
                }
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
            first.time.timeIntervalSince1970 > second.time.timeIntervalSince1970
        }
        return summaryMessageArray
    }
    
    public func storeLiveMessage(_ message: LiveMessage) throws {
        let keyName = "-msg-liveMessageRecipients"
        var arrayToAppend: [LiveMessage] = []
        if let arrayData = keychainSwift.getData(keyName) {
            let decoder = JSONDecoder()
            guard let decodedResponse = try? decoder.decode([LiveMessage].self, from: arrayData) else {
                print("Error decoding LiveMessageArrayData")
                keychainSwift.delete(keyName)
                throw MessageStoreError.poorlyFormattedLiveMessageArrayData
            }
            arrayToAppend = decodedResponse
        }
        for (index, storedMessage) in arrayToAppend.enumerated() {
            if storedMessage.recipient == message.recipient {
                arrayToAppend.remove(at: index)
            }
        }
        arrayToAppend.append(message)
        let encoder = JSONEncoder()
        let encodedArrayData = try! encoder.encode(arrayToAppend)
        keychainSwift.set(encodedArrayData, forKey: keyName)
        sendNotification(count: arrayToAppend.count)
    }
    
    public func getLiveMessages() throws -> [LiveMessage] {
        let keyName = "-msg-liveMessageRecipients"
        guard let arrayData = keychainSwift.getData(keyName) else {
            return []
        }
        let decoder = JSONDecoder()
        guard let decodedResponse = try? decoder.decode([LiveMessage].self, from: arrayData) else {
            print("Error decoding LiveMessageArrayData")
            keychainSwift.delete(keyName)
            throw MessageStoreError.poorlyFormattedLiveMessageArrayData
        }
        return decodedResponse
    }
    
    public func removeLiveMessageRecipient(_ recipient: ProtocolAddress) throws {
        let keyName = "-msg-liveMessageRecipients"
        var arrayToDeleteFrom: [LiveMessage] = []
        if let arrayData = keychainSwift.getData(keyName) {
            let decoder = JSONDecoder()
            guard let decodedResponse = try? decoder.decode([LiveMessage].self, from: arrayData) else {
                print("Error decoding LiveMessageArrayData")
                keychainSwift.delete(keyName)
                throw MessageStoreError.poorlyFormattedLiveMessageArrayData
            }
            arrayToDeleteFrom = decodedResponse
        }
        arrayToDeleteFrom.removeAll { element in
            element.recipient == recipient
        }
        let encoder = JSONEncoder()
        let encodedArrayData = try! encoder.encode(arrayToDeleteFrom)
        keychainSwift.set(encodedArrayData, forKey: keyName)
        sendNotification(count: arrayToDeleteFrom.count)
    }
    
}
