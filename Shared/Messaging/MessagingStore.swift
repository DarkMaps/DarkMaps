//
//  MessagingStore.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 25/12/2020.
//

import Foundation

public struct MessagingStore {
    
    private let keychainSwift: KeychainSwift
    private let notificationCentre = NotificationCenter.default
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    public init(localAddress: ProtocolAddress) {
        self.keychainSwift = KeychainSwift(keyPrefix: localAddress.combinedValue)
        self.decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
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
        let keyName = "-msg-rcv-\(sender.combinedValue)"
        guard let messageData = keychainSwift.getData(keyName) else {
            throw MessageStoreError.noMessageFromThisSender
        }
        guard let decodedResponse = try? decoder.decode(LocationMessage.self, from: messageData) else {
            keychainSwift.delete(keyName)
            throw MessageStoreError.poorlyFormattedMessageData
        }
        return decodedResponse
    }

    public func storeMessage(_ message: LocationMessage) throws {
        let keyName = "-msg-rcv-\(message.sender.combinedValue)"
        let jsonData = try encoder.encode(message)
        keychainSwift.set(jsonData, forKey: keyName)
    }

    public func removeMessage(sender: ProtocolAddress) throws {
        let keyName = "-msg-rcv-\(sender.combinedValue)"
        keychainSwift.delete(keyName)
    }
    
    public func getMessageSummary() throws -> [ShortLocationMessage] {
        var summaryMessageArray: [ShortLocationMessage] = []
        let keys = keychainSwift.allKeys
        for key in keys {
            if key.starts(with: "\(keychainSwift.keyPrefix)-msg-rcv-") {
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
        let encodedArrayData = try! encoder.encode(arrayToAppend)
        keychainSwift.set(encodedArrayData, forKey: keyName)
        sendNotification(count: arrayToAppend.count)
    }
    
    public func getLiveMessages() throws -> [LiveMessage] {
        let keyName = "-msg-liveMessageRecipients"
        guard let arrayData = keychainSwift.getData(keyName) else {
            return []
        }
        guard let decodedResponse = try? decoder.decode([LiveMessage].self, from: arrayData) else {
            print("Decoding live messages failed - deleting..")
            keychainSwift.delete(keyName)
            throw MessageStoreError.poorlyFormattedLiveMessageArrayData
        }
        return decodedResponse
    }
    
    public func getLiveMessage(address: ProtocolAddress) throws -> LiveMessage? {
        let keyName = "-msg-liveMessageRecipients"
        guard let arrayData = keychainSwift.getData(keyName) else {
            return nil
        }
        guard let decodedResponse = try? decoder.decode([LiveMessage].self, from: arrayData) else {
            print("Decoding live messages failed - deleting..")
            keychainSwift.delete(keyName)
            throw MessageStoreError.poorlyFormattedLiveMessageArrayData
        }
        for liveMessage in decodedResponse {
            if liveMessage.recipient == address {
                return liveMessage
            }
        }
        return nil
    }
    
    public func updateLiveMessage(newMessage: LiveMessage) throws {
        let keyName = "-msg-liveMessageRecipients"
        guard let arrayData = keychainSwift.getData(keyName) else {
            throw MessageStoreError.liveMessageRecipientDoesNotExist
        }
        guard var arrayToUpdate = try? decoder.decode([LiveMessage].self, from: arrayData) else {
            keychainSwift.delete(keyName)
            throw MessageStoreError.poorlyFormattedLiveMessageArrayData
        }
        // Remove old message
        arrayToUpdate.removeAll { element in
            element.recipient == newMessage.recipient
        }
        // Add new message
        arrayToUpdate.append(newMessage)
        let encodedArrayData = try! encoder.encode(arrayToUpdate)
        keychainSwift.set(encodedArrayData, forKey: keyName)
        sendNotification(count: arrayToUpdate.count)
    }
    
    public func removeLiveMessageRecipient(_ recipient: ProtocolAddress) throws {
        let keyName = "-msg-liveMessageRecipients"
        var arrayToDeleteFrom: [LiveMessage] = []
        if let arrayData = keychainSwift.getData(keyName) {
            guard let decodedResponse = try? decoder.decode([LiveMessage].self, from: arrayData) else {
                keychainSwift.delete(keyName)
                throw MessageStoreError.poorlyFormattedLiveMessageArrayData
            }
            arrayToDeleteFrom = decodedResponse
        }
        arrayToDeleteFrom.removeAll { element in
            element.recipient == recipient
        }
        let encodedArrayData = try! encoder.encode(arrayToDeleteFrom)
        keychainSwift.set(encodedArrayData, forKey: keyName)
        sendNotification(count: arrayToDeleteFrom.count)
    }
    
    public func storeFailedMessageDelete(_ messageID: Int) {
        let keyName = "-msg-rcv-failed-delete"
        var arrayOfStoredIds: [Int] = []
        if let currentData = keychainSwift.getData(keyName) {
            arrayOfStoredIds = (try? decoder.decode([Int].self, from: currentData)) ?? []
        }
        if !arrayOfStoredIds.contains(messageID) {
            arrayOfStoredIds.append(messageID)
        }
        do {
            let jsonData = try encoder.encode(arrayOfStoredIds)
            keychainSwift.set(jsonData, forKey: keyName)
        } catch {
            return
        }
    }

    public func removeMessagesPreviouslyFailedDelete(_ newMessageIdsToDelete: [Int]) -> [Int] {
        let keyName = "-msg-rcv-failed-delete"
        var arrayOfStoredIds: [Int] = []
        if let currentData = keychainSwift.getData(keyName) {
            arrayOfStoredIds = (try? decoder.decode([Int].self, from: currentData)) ?? []
        }
        let storedIdsSet = Set(arrayOfStoredIds)
        let newMessageIdsToDeleteSet = Set(newMessageIdsToDelete)
        return Array(newMessageIdsToDeleteSet.subtracting(storedIdsSet))
    }
    
}
