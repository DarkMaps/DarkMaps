//
//  MessageStoreTests.swift
//  SignalMapsTests
//
//  Created by Matthew Roche on 26/12/2020.
//

import XCTest

@testable import DarkMaps

class MessagingStoreTests: XCTestCase {
    
    let address = try! ProtocolAddress(name: "testUser@test.com", deviceId: UInt32(1))
    let keychainSwift = KeychainSwift(keyPrefix: "testUser@test.com.1")

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        keychainSwift.clear()
    }
    
    func testInitWithNewDetails() throws {
        XCTAssertNoThrow(MessagingStore(localAddress: address))
    }

    func testLoadMessage() throws {
        let messagingStore = MessagingStore(localAddress: address)
        
        let location = Location(latitude: 1.1, longitude: 1.1, time: Date())
        let message = LocationMessage(
            id: 1, sender: try ProtocolAddress(name: "testSender", deviceId: 1),
            location: location
        )
        let keyName = "-msg-rcv-\(message.sender.combinedValue)"
        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .iso8601
        let jsonData = try jsonEncoder.encode(message)
        keychainSwift.set(jsonData, forKey: keyName)
        
        let receivedMessage = try messagingStore.loadMessage(sender:message.sender)
        
        XCTAssertEqual(receivedMessage.sender.combinedValue, message.sender.combinedValue)
        XCTAssertEqual(receivedMessage.location!.latitude, message.location!.latitude)
        XCTAssertEqual(receivedMessage.location!.longitude, message.location!.longitude)
    }
    
    func testStoreMessage() throws {
        let messagingStore = MessagingStore(localAddress: address)
        
        let location = Location(latitude: 1.1, longitude: 1.1, time: Date())
        let message = LocationMessage(id: 1, 
            sender: try ProtocolAddress(name: "testSender", deviceId: 1),
            location: location
        )
        
        try messagingStore.storeMessage(message)
        
        let keyName = "-msg-rcv-\(message.sender.combinedValue)"
        let receivedMessageData = keychainSwift.getData(keyName)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let receivedMessage = try! decoder.decode(LocationMessage.self, from: receivedMessageData!)
        
        XCTAssertEqual(receivedMessage.sender.combinedValue, message.sender.combinedValue)
        XCTAssertEqual(receivedMessage.location!.latitude, message.location!.latitude)
        XCTAssertEqual(receivedMessage.location!.longitude, message.location!.longitude)
    }
    
    func testRemoveMessage() throws {
        let messagingStore = MessagingStore(localAddress: address)
        
        let location = Location(latitude: 1.1, longitude: 1.1, time: Date())
        let message = LocationMessage(
            id: 1, sender: try ProtocolAddress(name: "testSender", deviceId: 1),
            location: location
        )
        let keyName = "-msg-rcv-\(message.sender.combinedValue)"
        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .iso8601
        let jsonData = try jsonEncoder.encode(message)
        keychainSwift.set(jsonData, forKey: keyName)
        
        XCTAssertNoThrow(try messagingStore.removeMessage(sender: message.sender))
        
        let receivedMessageData = keychainSwift.getData(keyName)
        XCTAssertNil(receivedMessageData)
    }
    
    func testClearAllMessages() throws {
        
        let messagingStore = MessagingStore(localAddress: address)
        
        let location = Location(latitude: 1.1, longitude: 1.1, time: Date())
        let message = LocationMessage(
            id: 1, sender: try ProtocolAddress(name: "testSender", deviceId: 1),
            location: location
        )
        let keyName = "-msg-rcv-\(message.sender.combinedValue)"
        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .iso8601
        let jsonData = try jsonEncoder.encode(message)
        keychainSwift.set(jsonData, forKey: keyName)
        
        let location2 = Location(latitude: 1.1, longitude: 1.1, time: Date())
        let message2 = LocationMessage(
            id: 1, sender: try ProtocolAddress(name: "testSender2", deviceId: 1),
            location: location2
        )
        let keyName2 = "-msg-rcv-\(message2.sender.combinedValue)"
        let jsonData2 = try jsonEncoder.encode(message2)
        keychainSwift.set(jsonData2, forKey: keyName2)
        
        messagingStore.clearAllData()
        
        let receivedMessageData = keychainSwift.getData(keyName)
        XCTAssertNil(receivedMessageData)
        let receivedMessageData2 = keychainSwift.getData(keyName2)
        XCTAssertNil(receivedMessageData2)
        
    }
    
    func testGetMessageSummary() throws {
        
        let messagingStore = MessagingStore(localAddress: address)
        
        let location = Location(latitude: 1.1, longitude: 1.1, time: Date())
        let message = LocationMessage(
            id: 1, sender: try ProtocolAddress(name: "testSender", deviceId: 1),
            location: location
        )
        let keyName = "-msg-rcv-\(message.sender.combinedValue)"
        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .iso8601
        let jsonData = try jsonEncoder.encode(message)
        keychainSwift.set(jsonData, forKey: keyName)
        
        sleep(2)
        
        let location2 = Location(latitude: 1.1, longitude: 1.1, time: Date())
        let message2 = LocationMessage(
            id: 1, sender: try ProtocolAddress(name: "testSender2", deviceId: 1),
            location: location2
        )
        let keyName2 = "-msg-rcv-\(message2.sender.combinedValue)"
        let jsonData2 = try jsonEncoder.encode(message2)
        keychainSwift.set(jsonData2, forKey: keyName2)
        
        let summary = try messagingStore.getMessageSummary()
        
        XCTAssertEqual(summary.count, 2)
        XCTAssertEqual(Int(summary[1].time.timeIntervalSince1970), Int(message.location!.time.timeIntervalSince1970))
        XCTAssertGreaterThan(summary[0].time.timeIntervalSince1970, summary[1].time.timeIntervalSince1970)
        
    }
    
    func testStoreLiveMessageRecipient() throws {
        let messagingStore = MessagingStore(localAddress: address)
        
        let recipient = try ProtocolAddress(name: "testRecipient", deviceId: 1)
        let liveMessage = LiveMessage(recipient: recipient, expiry: Date())
        try messagingStore.storeLiveMessage(liveMessage)
        
        let arrayData = keychainSwift.getData("-msg-liveMessageRecipients")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedArray = try decoder.decode([LiveMessage].self, from: arrayData!)
        
        XCTAssertEqual(decodedArray.count, 1)
        XCTAssertEqual(decodedArray[0].recipient, recipient)
    }
    
    func testGetLiveMessageRecipients() throws {
        let messagingStore = MessagingStore(localAddress: address)
        
        let recipient1 = try ProtocolAddress(name: "testRecipient1", deviceId: 1)
        let liveMessage1 = LiveMessage(recipient: recipient1, expiry: Date())
        let recipient2 = try ProtocolAddress(name: "testRecipient2", deviceId: 1)
        let liveMessage2 = LiveMessage(recipient: recipient2, expiry: Date())
        let array = [liveMessage1, liveMessage2]
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let encodedArrayData = try encoder.encode(array)
        keychainSwift.set(encodedArrayData, forKey: "-msg-liveMessageRecipients")
        
        let messageRecipients = try messagingStore.getLiveMessages()
        
        XCTAssertEqual(messageRecipients.count, 2)
        XCTAssertEqual(messageRecipients[0].recipient, recipient1)
    }
    
    func testRemoveLiveMessageRecipient() throws {
        let messagingStore = MessagingStore(localAddress: address)
        
        let recipient1 = try ProtocolAddress(name: "testRecipient1", deviceId: 1)
        let liveMessage1 = LiveMessage(recipient: recipient1, expiry: Date())
        let recipient2 = try ProtocolAddress(name: "testRecipient2", deviceId: 1)
        let liveMessage2 = LiveMessage(recipient: recipient2, expiry: Date())
        let array = [liveMessage1, liveMessage2]
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let encodedArrayData = try encoder.encode(array)
        keychainSwift.set(encodedArrayData, forKey: "-msg-liveMessageRecipients")
        
        try messagingStore.removeLiveMessageRecipient(recipient2)
        
        let arrayData = keychainSwift.getData("-msg-liveMessageRecipients")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedArray = try decoder.decode([LiveMessage].self, from: arrayData!)
        
        XCTAssertEqual(decodedArray.count, 1)
        XCTAssertEqual(decodedArray[0].recipient, recipient1)
    }
    
    func testStoreFailedDeletemessage() throws {
        let messagingStore = MessagingStore(localAddress: address)
        messagingStore.storeFailedMessageDelete(3464)
        let currentData = keychainSwift.getData("-msg-rcv-failed-delete")!
        let decoder = JSONDecoder()
        let arrayOfStoredIds = try! decoder.decode([Int].self, from: currentData)
        XCTAssert(arrayOfStoredIds.contains(3464))
    }
    
    func testParseFailedDeleteMessage() throws {
        let messagingStore = MessagingStore(localAddress: address)
        let arrayOfStoredIds = [23785, 235324, 234234]
        let encoder = JSONEncoder()
        let data = try! encoder.encode(arrayOfStoredIds)
        keychainSwift.set(data, forKey: "-msg-rcv-failed-delete")
        let idsToParse = [23785, 235324, 1]
        let parsedIds = messagingStore.removeMessagesPreviouslyFailedDelete(idsToParse)
        XCTAssertEqual(parsedIds, [1])
    }

}
