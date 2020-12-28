//
//  MessageStoreTests.swift
//  SignalMapsTests
//
//  Created by Matthew Roche on 26/12/2020.
//

import XCTest

@testable import SignalMaps

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
        
        let location = Location(latitude: 1.1, longitude: 1.1)
        let message = LocationMessage(
            id: 1, sender: try ProtocolAddress(name: "testSender", deviceId: 1),
            location: location,
            lastReceived: 1
        )
        let keyName = "-msg-\(message.sender.combinedValue)"
        let jsonEncoder = JSONEncoder()
        let jsonData = try jsonEncoder.encode(message)
        keychainSwift.set(jsonData, forKey: keyName)
        
        let receivedMessage = try messagingStore.loadMessage(sender:message.sender)
        
        XCTAssertEqual(receivedMessage.sender.combinedValue, message.sender.combinedValue)
        XCTAssertEqual(receivedMessage.lastReceived, message.lastReceived)
        XCTAssertEqual(receivedMessage.location!.latitude, message.location!.latitude)
        XCTAssertEqual(receivedMessage.location!.longitude, message.location!.longitude)
    }
    
    func testStoreMessage() throws {
        let messagingStore = MessagingStore(localAddress: address)
        
        let location = Location(latitude: 1.1, longitude: 1.1)
        let message = LocationMessage(id: 1, 
            sender: try ProtocolAddress(name: "testSender", deviceId: 1),
            location: location,
            lastReceived: 1
        )
        
        try messagingStore.storeMessage(message)
        
        let keyName = "-msg-\(message.sender.combinedValue)"
        let receivedMessageData = keychainSwift.getData(keyName)
        let decoder = JSONDecoder()
        let receivedMessage = try! decoder.decode(LocationMessage.self, from: receivedMessageData!)
        
        XCTAssertEqual(receivedMessage.sender.combinedValue, message.sender.combinedValue)
        XCTAssertEqual(receivedMessage.lastReceived, message.lastReceived)
        XCTAssertEqual(receivedMessage.location!.latitude, message.location!.latitude)
        XCTAssertEqual(receivedMessage.location!.longitude, message.location!.longitude)
    }
    
    func testRemoveMessage() throws {
        let messagingStore = MessagingStore(localAddress: address)
        
        let location = Location(latitude: 1.1, longitude: 1.1)
        let message = LocationMessage(
            id: 1, sender: try ProtocolAddress(name: "testSender", deviceId: 1),
            location: location,
            lastReceived: 1
        )
        let keyName = "-msg-\(message.sender.combinedValue)"
        let jsonEncoder = JSONEncoder()
        let jsonData = try jsonEncoder.encode(message)
        keychainSwift.set(jsonData, forKey: keyName)
        
        XCTAssertNoThrow(try messagingStore.removeMessage(sender: message.sender))
        
        let receivedMessageData = keychainSwift.getData(keyName)
        XCTAssertNil(receivedMessageData)
    }
    
    func testClearAllMessages() throws {
        
        let messagingStore = MessagingStore(localAddress: address)
        
        let location = Location(latitude: 1.1, longitude: 1.1)
        let message = LocationMessage(
            id: 1, sender: try ProtocolAddress(name: "testSender", deviceId: 1),
            location: location,
            lastReceived: 1
        )
        let keyName = "-msg-\(message.sender.combinedValue)"
        let jsonEncoder = JSONEncoder()
        let jsonData = try jsonEncoder.encode(message)
        keychainSwift.set(jsonData, forKey: keyName)
        
        let location2 = Location(latitude: 1.1, longitude: 1.1)
        let message2 = LocationMessage(
            id: 1, sender: try ProtocolAddress(name: "testSender2", deviceId: 1),
            location: location2,
            lastReceived: 2
        )
        let keyName2 = "-msg-\(message2.sender.combinedValue)"
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
        
        let location = Location(latitude: 1.1, longitude: 1.1)
        let message = LocationMessage(
            id: 1, sender: try ProtocolAddress(name: "testSender", deviceId: 1),
            location: location,
            lastReceived: 1
        )
        let keyName = "-msg-\(message.sender.combinedValue)"
        let jsonEncoder = JSONEncoder()
        let jsonData = try jsonEncoder.encode(message)
        keychainSwift.set(jsonData, forKey: keyName)
        
        let location2 = Location(latitude: 1.1, longitude: 1.1)
        let message2 = LocationMessage(
            id: 1, sender: try ProtocolAddress(name: "testSender2", deviceId: 1),
            location: location2,
            lastReceived: 2
        )
        let keyName2 = "-msg-\(message2.sender.combinedValue)"
        let jsonData2 = try jsonEncoder.encode(message2)
        keychainSwift.set(jsonData2, forKey: keyName2)
        
        let summary = try messagingStore.getMessageSummary()
        
        XCTAssertEqual(summary.count, 2)
        XCTAssertEqual(summary[1].lastReceived, message.lastReceived)
        XCTAssertGreaterThan(summary[0].lastReceived, summary[1].lastReceived)
        
    }

}
