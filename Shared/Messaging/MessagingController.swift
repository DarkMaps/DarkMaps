//
//  MessagingController.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 26/12/2020.
//

import Foundation
import SwiftLocation

public class MessagingController {
    
    private var serverAddress: String?
    private var authToken: String?
    private var messagingStore: MessagingStore? = nil
    private var simpleSignalSwiftEncryptionAPI: SimpleSignalSwiftEncryptionAPI? = nil
    private let notificationCentre = NotificationCenter.default
    
    init(userName: String? = nil, serverAddress: String? = nil, authToken: String? = nil) throws {
        self.serverAddress = serverAddress
        self.authToken = authToken
        if let userName = userName {
            guard let address = try? ProtocolAddress(name: userName, deviceId: UInt32(1)) else {
                throw MessagingControllerError.unableToCreateAddress
            }
            
            guard let simpleSignalSwiftEncryptionAPI = try? SimpleSignalSwiftEncryptionAPI(address: address) else {
                throw MessagingControllerError.unableToCreateEncryptionHandler
            }
            self.simpleSignalSwiftEncryptionAPI = simpleSignalSwiftEncryptionAPI
            
            self.messagingStore = MessagingStore(
                localAddress: address
            )
            
            notificationCentre.addObserver(self,
                                           selector: #selector(self.handleLocationUpdateNotification(_:)),
                                           name: .locationController_NewLocationReceived,
                                           object: nil)
            
        }
    }
    
    @objc private func handleLocationUpdateNotification(_ notification: NSNotification) {
        guard let serverAddress = self.serverAddress else {
            print("No server address available")
            return
        }
        guard let authToken = self.authToken else {
            print("No auth token available")
            return
        }
        guard let locationData = notification.userInfo?["location"] as? GPSLocationRequest.ProducedData else {
            print("No location found in Location Update Notification")
            return
        }
        guard let messageStore = self.messagingStore else {
            print("Unable to load messaging store")
            return
        }
        guard var allRecipients = try? messageStore.getLiveMessages() else {
            print("No recipients found")
            return
        }
        allRecipients = parseExpiredLiveMessages(allRecipients)
        let locationToSend = Location(
            latitude: locationData.coordinate.latitude,
            longitude: locationData.coordinate.longitude,
            time: Date()
            )
        for recipient in allRecipients {
            var personalLocationToSend = locationToSend
            personalLocationToSend.liveExpiryDate = Date(timeIntervalSince1970: Double(recipient.expiry))
            self.sendMessage(
                recipientName: recipient.recipient.name,
                recipientDeviceId: Int(recipient.recipient.deviceId),
                message: personalLocationToSend,
                serverAddress: serverAddress,
                authToken: authToken) {
                sendMessageResponse in
                switch sendMessageResponse {
                case .failure(let error):
                    print("Error sending message")
                    print(error)
                case .success():
                    print("Message successfully sent to \(recipient.recipient.combinedValue)")
                }
            }
        }
    }
    
    private func parseExpiredLiveMessages(_ array: [LiveMessage]) -> [LiveMessage] {
        return array.filter { $0.expiry > Int(Date().timeIntervalSince1970) }
    }
    
    func createDevice(userName: String, serverAddress: String, authToken: String, completionHandler: @escaping (_: Result<Int, MessagingControllerError>) -> ()) {
        
        guard let address = try? ProtocolAddress(name: userName, deviceId: UInt32(1)) else {
            completionHandler(.failure(.unableToCreateAddress))
            return
        }
        
        guard let simpleSignalSwiftEncryptionAPI = try? SimpleSignalSwiftEncryptionAPI(address: address) else {
            completionHandler(.failure(.unableToCreateEncryptionHandler))
            return
        }
        self.simpleSignalSwiftEncryptionAPI = simpleSignalSwiftEncryptionAPI
        
        self.messagingStore = MessagingStore(
            localAddress: address
        )
        
        if simpleSignalSwiftEncryptionAPI.deviceExists(authToken: authToken, serverAddress: serverAddress) {
            print("Device already exists locally")
            if let registrationId = simpleSignalSwiftEncryptionAPI.registrationId {
                completionHandler(.success(registrationId))
                return
            } else {
                simpleSignalSwiftEncryptionAPI.deleteLocalDeviceDetails()
            }
        }
        
        let createDeviceResult = simpleSignalSwiftEncryptionAPI.createDevice(authToken: authToken, serverAddress: serverAddress)
        switch createDeviceResult {
        case .failure(let error):
            print("Error creating device")
            print(error)
            if error == .deviceExists {
                completionHandler(.failure(.unableToCreateDevice))
            } else {
                completionHandler(.failure(.unableToCreateDevice))
            }
        case .success(let registrationId):
            print("Success creating device")
            completionHandler(.success(registrationId))
        }
        
    }
    
    func sendMessage(recipientName: String, recipientDeviceId: Int, message: Location, serverAddress: String, authToken: String, completionHandler: @escaping (_: Result<Void, MessagingControllerError>) -> ()) {
        print("Attempting send message")
        
        guard let simpleSignalSwiftEncryptionAPI = self.simpleSignalSwiftEncryptionAPI else {
            completionHandler(.failure(.noDeviceCreated))
            return
        }
        
        DispatchQueue.global(qos: .utility).async {
            let encoder = JSONEncoder()
            guard let locationData = try? encoder.encode(message)  else {
                completionHandler(.failure(.poorlyFormattedLocation))
                return
            }
            guard let locationString = String(data: locationData, encoding: .utf8) else {
                completionHandler(.failure(.poorlyFormattedLocation))
                return
            }
            let response = simpleSignalSwiftEncryptionAPI.sendMessage(
                message: locationString,
                recipientName: recipientName,
                recipientDeviceId: UInt32(recipientDeviceId),
                authToken: authToken,
                serverAddress: serverAddress)
            DispatchQueue.main.async {
                switch response {
                    case .success():
                        print("Message sent successfully")
                        completionHandler(.success(()))
                    case let .failure(error):
                        print("Message send unsuccessful")
                        print(error)
                        completionHandler(.failure(.unableToSendMessage))
                    }
            }
        }
    }
    
    func getMessages(serverAddress: String, authToken: String, completionHandler: @escaping (_: Result<Void, MessagingControllerError>) -> ()) {
        print("Attempting to retrieve messages")
        guard let simpleSignalSwiftEncryptionAPI = self.simpleSignalSwiftEncryptionAPI else {
            completionHandler(.failure(.noDeviceCreated))
            return
        }
        guard let messagingStore = self.messagingStore else {
            completionHandler(.failure(.noDeviceCreated))
            return
        }
        var messageIdsToDelete: [Int] = []
        DispatchQueue.global(qos: .utility).async {
            let response = simpleSignalSwiftEncryptionAPI.getMessages(authToken: authToken, serverAddress: serverAddress)
            DispatchQueue.main.async {
                switch response {
                case .success(let outputArray):
                    for output in outputArray {
                        messageIdsToDelete.append(output.id)
                        do {
                            if let error = output.error {
                                print("Found error in message output")
                                let newMessage = LocationMessage(
                                    id: output.id,
                                    sender: output.senderAddress,
                                    error: error)
                                print(newMessage)
                                try messagingStore.storeMessage(newMessage)
                                continue
                            } else {
                                let decoder = JSONDecoder()
                                guard let messageString = output.message else {
                                    print("No message data found in message")
                                    let newMessage = LocationMessage(
                                        id: output.id,
                                        sender: output.senderAddress,
                                        error: .badFormat)
                                    try messagingStore.storeMessage(newMessage)
                                    continue
                                }
                                guard let locationData = messageString.data(using: .utf8) else {
                                    print("Unable to create message string")
                                    let newMessage = LocationMessage(
                                        id: output.id,
                                        sender: output.senderAddress,
                                        error: .badFormat)
                                    try messagingStore.storeMessage(newMessage)
                                    continue
                                }
                                guard let decodedLocation = try? decoder.decode(Location.self, from: locationData) else {
                                    let newMessage = LocationMessage(
                                        id: output.id,
                                        sender: output.senderAddress,
                                        error: .badFormat)
                                    try messagingStore.storeMessage(newMessage)
                                    continue
                                }
                                let newMessage = LocationMessage(
                                    id: output.id,
                                    sender: output.senderAddress,
                                    location: decodedLocation)
                                try messagingStore.storeMessage(newMessage)
                            }
                        } catch {
                            completionHandler(.failure(.unableToDecryptMessage))
                        }
                    }
                    print("Finished processing messages")
                    
                    if messageIdsToDelete.count > 0 {
                     
                        self.handleDeleteMessages(messageIds: messageIdsToDelete, serverAddress: serverAddress, authToken: authToken) { deleteMessageOutcome in
                            switch deleteMessageOutcome {
                            case .failure(let error):
                                print(error)
                                completionHandler(.failure(.unableToDeleteMessage))
                            case .success():
                                
                                self.handleUpdateDevice(serverAddress: serverAddress, authToken: authToken) { updateDeviceOutcome in
                                    
                                    switch updateDeviceOutcome {
                                    case .failure(let error):
                                        print(error)
                                        completionHandler(.failure(.unableToUpdateDeviceKeys))
                                    case .success():
                                        completionHandler(.success(()))
                                    }
                                    
                                }
                            }
                        }
                        
                    } else {
                        completionHandler(.success(()))
                    }
                    
                case .failure(let error):
                    print("Message retrieval unsuccessful")
                    if error == .senderHasNoRegisteredDevice {
                        completionHandler(.failure(.noDeviceOnServer))
                    } else {
                        completionHandler(.failure(.unableToRetrieveMessages))
                    }
                }
            }
        }
    }
    
    private func handleDeleteMessages(messageIds: [Int], serverAddress: String, authToken: String, completionHandler: @escaping (_: Result<Void, MessagingControllerError>) -> ()) {
        
        guard let simpleSignalSwiftEncryptionAPI = self.simpleSignalSwiftEncryptionAPI else {
            completionHandler(.failure(.noDeviceCreated))
            return
        }
        
        DispatchQueue.global(qos: .utility).async {
            let response = simpleSignalSwiftEncryptionAPI.deleteMessage(authToken: authToken, serverAddress: serverAddress, messageIds: messageIds)
            switch response {
            case .success(let output):
                print("Messages deleted")
                print(output)
                completionHandler(.success(()))
            case .failure(let error):
                print("Error deleting messages")
                print(error)
                completionHandler(.failure(.unableToDeleteMessage))
            }
        }
    }
    
    public func handleDeleteMessageLocally(sender: ProtocolAddress) throws {
        guard let messagingStore = self.messagingStore else {
            throw MessagingControllerError.noDeviceCreated
        }
        try messagingStore.removeMessage(sender: sender)
    }
    
    private func handleUpdateDevice(serverAddress: String, authToken: String, completionHandler: @escaping (_: Result<Void, MessagingControllerError>) -> ()) {
        guard let simpleSignalSwiftEncryptionAPI = self.simpleSignalSwiftEncryptionAPI else {
            completionHandler(.failure(.noDeviceCreated))
            return
        }
        DispatchQueue.global(qos: .utility).async {
            let preKeyResponse = simpleSignalSwiftEncryptionAPI.updatePreKeys(authToken: authToken, serverAddress: serverAddress)
            switch preKeyResponse {
            case .success():
                print("Success updating prekeys")
                let signedPreKeyResponse = simpleSignalSwiftEncryptionAPI.updateSignedPreKey(authToken: authToken, serverAddress: serverAddress)
                switch signedPreKeyResponse {
                case .success():
                    print("Success updating signed prekey")
                    completionHandler(.success(()))
                case .failure(let error):
                    print("Failed to update signed prekey")
                    print(error)
                    completionHandler(.failure(.unableToUpdateDeviceKeys))
                }
                
            case .failure(let error):
                print("Failed to update prekeys")
                print(error)
                completionHandler(.failure(.unableToUpdateDeviceKeys))
            }
        }
    }
    
    func deleteDevice(userName: String? = nil, serverAddress: String, authToken: String, completionHandler: @escaping (_: Result<Void, MessagingControllerError>) -> ()) {
    
        print("Attempting to delete device")
        
        var userNameForConstruction: String? = userName
        if userNameForConstruction == nil {
            guard let simpleSignalSwiftEncryptionAPI = self.simpleSignalSwiftEncryptionAPI else {
                completionHandler(.failure(.needToProvideUsername))
                return
            }
            userNameForConstruction = simpleSignalSwiftEncryptionAPI.address.name
        }
        
        guard let address = try? ProtocolAddress(name: userNameForConstruction!, deviceId: UInt32(1)) else {
            completionHandler(.failure(.unableToCreateAddress))
            return
        }
        
        guard let simpleSignalSwiftEncryptionAPI = try? SimpleSignalSwiftEncryptionAPI(address: address) else {
            completionHandler(.failure(.unableToCreateEncryptionHandler))
            return
        }
        
        DispatchQueue.global(qos: .utility).async {
            let response = simpleSignalSwiftEncryptionAPI.deleteDevice(authToken: authToken, serverAddress: serverAddress)
            DispatchQueue.main.async {
                switch response {
                case .success():
                    self.simpleSignalSwiftEncryptionAPI = nil
                    completionHandler(.success(()))
                case .failure(let error):
                    print("Error deleting device")
                    print(error)
                    completionHandler(.failure(.unableToDeleteDevice))
                }
            }
        }
    }
    
    func addLiveMessage(recipientName: String, recipientDeviceId: Int, expiry: Int) throws {
        guard let messagingStore = self.messagingStore else {
            throw MessagingControllerError.noDeviceCreated
        }
        let recipientAddress = try ProtocolAddress(name: recipientName, deviceId: UInt32(recipientDeviceId))
        let liveMessage = LiveMessage(recipient: recipientAddress, expiry: expiry)
        try messagingStore.storeLiveMessage(liveMessage)
    }
    
    func removeLiveMessageRecipient(recipientAddress: ProtocolAddress) throws {
        guard let messagingStore = self.messagingStore else {
            throw MessagingControllerError.noDeviceCreated
        }
        try messagingStore.removeLiveMessageRecipient(recipientAddress)
    }
    
    func getLiveMessageRecipients() throws -> [LiveMessage] {
        guard let messagingStore = self.messagingStore else {
            throw MessagingControllerError.noDeviceCreated
        }
        return try messagingStore.getLiveMessages()
    }
    
    func deleteAllLocalData() {
        if let messagingStore = self.messagingStore {
            messagingStore.clearAllData()
        }
        self.messagingStore = nil
        if let simpleSignalSwiftEncryptionAPI = self.simpleSignalSwiftEncryptionAPI {
            simpleSignalSwiftEncryptionAPI.deleteLocalDeviceDetails()
        }
        self.simpleSignalSwiftEncryptionAPI = nil
    }
    
}
