//
//  EndToEndTests.swift
//  SignalMapsTests
//
//  Created by Matthew Roche on 26/12/2020.
//

import XCTest

@testable import DarkMaps

class EndToEndTests: XCTestCase {
    
    let keychainSwift = KeychainSwift()
    
    let baseURL = "http://127.0.0.1:8000"

    override func setUpWithError() throws {
    // Put setup code here. This method is called before the invocation of each test method in the class.
        keychainSwift.clear()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testEndToEnd() throws {
        
        let expectation = XCTestExpectation(description: "Successfully logs in")
        
        let authorisationController = AuthorisationController()
        
        // Create first user
        let username1 = "testUser1@test.com"
        let password1 = "testPassword1"
        authorisationController.login(username: username1, password: password1, serverAddress: baseURL) { (loginOutcome1) in
            let userDetails1: LoggedInUser
            switch loginOutcome1 {
            case .success(let userDetails):
                userDetails1 = userDetails
            default:
                print("Error logging in")
                return
            }
            
            
            // Create second user
            let username2 = "testUser2@test.com"
            let password2 = "testPassword2"
            authorisationController.login(username: username2, password: password2, serverAddress: self.baseURL) { (loginOutcome2) in
                let userDetails2: LoggedInUser
                switch loginOutcome2 {
                case .success(let userDetails):
                    userDetails2 = userDetails
                default:
                    print("Error logging in")
                    return
                }
    
                do {
                    try self.startEndToEndEncryptionTests(userDetails1: userDetails1, userDetails2: userDetails2, expectation: expectation)
                } catch {
                    print("Error in startEndToEndEncryptionTests")
                }
                
            }
        }
        
        wait(for: [expectation], timeout: 20.0)
    }
    
    func startEndToEndEncryptionTests(userDetails1: LoggedInUser, userDetails2: LoggedInUser, expectation: XCTestExpectation) throws {
        
        let user1MessagingController = try MessagingController()
        let user2MessagingController = try MessagingController()
        
        user1MessagingController.createDevice(userName: userDetails1.userName, serverAddress: userDetails1.serverAddress, authToken: userDetails1.authCode) { createDeviceResult1 in
            switch createDeviceResult1 {
            case .failure(let error):
                print("Failed to create device")
                print(error)
            case .success(let registrationId):
                print("Created device for user1 with registrationId: \(registrationId)")
                
                user2MessagingController.createDevice(userName: userDetails2.userName, serverAddress: userDetails2.serverAddress, authToken: userDetails2.authCode) { createDeviceResult2 in
                    switch createDeviceResult2 {
                    case .failure(let error):
                        print("Failed to create device")
                        print(error)
                    case .success(let registrationId):
                        print("Created device for user2 with registrationId: \(registrationId)")
                        do {
                            try self.startEndToEndEncryptionMessagingTests(userDetails1: userDetails1, userDetails2: userDetails2, user1MessagingController: user1MessagingController, user2MessagingController: user2MessagingController, expectation: expectation)
                        } catch {
                            print("Error in startEndToEndEncryptionMessagingTests")
                        }
                    }
                }
            }
        }
    }
        
    func startEndToEndEncryptionMessagingTests(userDetails1: LoggedInUser, userDetails2: LoggedInUser, user1MessagingController: MessagingController, user2MessagingController: MessagingController, expectation: XCTestExpectation) throws {
        
        let location = Location(latitude: 1.2345, longitude: 6.7891, time: Date())
        
        user1MessagingController.sendMessage(recipientName: userDetails2.userName, recipientDeviceId: userDetails2.deviceId, message: location, serverAddress: userDetails1.serverAddress, authToken: userDetails1.authCode) {
            (sendMessageOutcome) in
            switch sendMessageOutcome {
            case .failure(let error):
                print("Error sending message")
                print(error)
            case .success:
                
                user2MessagingController.getMessages(serverAddress: userDetails2.serverAddress, authToken: userDetails2.authCode) {
                    (getMessageOutcome) in
                    switch getMessageOutcome {
                    case .failure(let error):
                        print("Error getting messages")
                        print(error)
                    case .success:
                        print("Success getting messages")
                        
                        
                        do {
                            let user2Address = try ProtocolAddress(name: userDetails2.userName, deviceId: UInt32(userDetails2.deviceId))
                            let messageStore = MessagingStore(localAddress: user2Address)
                            let messageSummary = try messageStore.getMessageSummary()
                            print(messageSummary)
                            try self.startEndToEndEncryptionMessagingReturnTests(userDetails1: userDetails1, userDetails2: userDetails2, user1MessagingController: user1MessagingController, user2MessagingController: user2MessagingController, expectation: expectation)
                            
                            
                        } catch {
                            print("Error getting message summary")
                        }
                    }
                }
            }
        }
    }
    
    func startEndToEndEncryptionMessagingReturnTests(userDetails1: LoggedInUser, userDetails2: LoggedInUser, user1MessagingController: MessagingController, user2MessagingController: MessagingController, expectation: XCTestExpectation) throws {
        
        let location = Location(latitude: 1.2345, longitude: 6.7891, time: Date())
        print("Sending return message")
        user2MessagingController.sendMessage(recipientName: userDetails1.userName, recipientDeviceId: userDetails1.deviceId, message: location, serverAddress: userDetails2.serverAddress, authToken: userDetails2.authCode) {
            (sendMessageOutcome) in
            switch sendMessageOutcome {
            case .failure(let error):
                print("Error sending message")
                print(error)
            case .success:
                
                user1MessagingController.getMessages(serverAddress: userDetails1.serverAddress, authToken: userDetails1.authCode) {
                    (getMessageOutcome) in
                    switch getMessageOutcome {
                    case .failure(let error):
                        print("Error getting messages")
                        print(error)
                    case .success:
                        print("Success getting messages")
                        
                        
                        do {
                            let user1Address = try ProtocolAddress(name: userDetails1.userName, deviceId: UInt32(userDetails1.deviceId))
                            let messageStore = MessagingStore(localAddress: user1Address)
                            let messageSummary = try messageStore.getMessageSummary()
                            print(messageSummary)
                            self.startDeleteDevices(userDetails1: userDetails1, userDetails2: userDetails2, user1MessagingController: user1MessagingController, user2MessagingController: user2MessagingController, expectation: expectation)
                            
                            
                        } catch {
                            print("Error getting message summary")
                        }
                    }
                }
            }
        }
    }
    
    func startDeleteDevices(userDetails1: LoggedInUser, userDetails2: LoggedInUser, user1MessagingController: MessagingController, user2MessagingController: MessagingController, expectation: XCTestExpectation) {
        
        user1MessagingController.deleteDevice(serverAddress: userDetails1.serverAddress, authToken: userDetails1.authCode) { deleteDeviceResult1 in
            
            switch deleteDeviceResult1 {
            case .failure(let error):
                print("Failure deleting device 1")
                print(error)
            case .success():
                
                user2MessagingController.deleteDevice(serverAddress: userDetails2.serverAddress, authToken: userDetails2.authCode) { deleteDeviceResult2 in
                    switch deleteDeviceResult2 {
                    case .failure(let error):
                        print("Failure deleting device 2")
                        print(error)
                    case .success():
                        print("Success deleting devices")
                        expectation.fulfill()
                    }
                }
            }
        }
    }
}
