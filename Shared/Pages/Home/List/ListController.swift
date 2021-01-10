//
//  List Controller.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 08/12/2020.
//

import SwiftUI

struct ListController: View {
    
    @EnvironmentObject var appState: AppState
    
    @State var receivingMessageArray: [ShortLocationMessage] = []
    @State var sendingMessageArray: [LiveMessage] = []
    @State var getMessagesInProgress: Bool = false
    @State var directionLabels = ["Receiving (0)", "Sending (0)"]
    
    func updateLabels() {
        print("updateLabels")
        directionLabels[0] = "Receiving (\(self.receivingMessageArray.count))"
        directionLabels[1] = "Sending (\(self.sendingMessageArray.count))"
    }
    
    func getStoredMessages() {
        
        guard let messagingController = appState.messagingController else {
            appState.displayedError = IdentifiableError(ListViewErrors.noUserLoggedIn)
            return
        }
        
        do {
            self.receivingMessageArray = try messagingController.getMessageSummary()
        } catch {
            print("Error getting received messages")
            print(error)
            appState.displayedError = IdentifiableError(ListViewErrors.unableToRetrieveMessages)
        }
        
        do {
            self.sendingMessageArray = try messagingController.getLiveMessages()
            print("Got sending messages")
        } catch {
            print("Error getting sent messages")
            print(error)
            appState.displayedError = IdentifiableError(ListViewErrors.unableToRetrieveMessages)
        }
        
        self.updateLabels()
    }
    
    func performSync() {
        getMessagesInProgress = true
        
        guard let loggedInUser = appState.loggedInUser else {
            appState.displayedError = IdentifiableError(ListViewErrors.noUserLoggedIn)
            return
        }
        
        guard let messagingController = appState.messagingController else {
            appState.displayedError = IdentifiableError(ListViewErrors.noUserLoggedIn)
            return
        }
        
        messagingController.getMessages(serverAddress: loggedInUser.serverAddress, authToken: loggedInUser.authCode) { getMessagesOutcome in
            
            getMessagesInProgress = false
            
            switch getMessagesOutcome {
            case .failure(let error):
                if error == .noDeviceOnServer {
                    messagingController.deleteAllLocalData()
                    let authorisationController = AuthorisationController()
                    authorisationController.logUserOut(authToken: loggedInUser.authCode, serverAddress: loggedInUser.serverAddress) { logOutOutcome in
                        switch logOutOutcome {
                        case .success():
                            appState.loggedInUser = nil
                        case .failure(let error):
                            appState.displayedError = IdentifiableError(error)
                            appState.loggedInUser = nil
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        appState.displayedError = IdentifiableError(error)
                    }
                }
            case .success():
                do {
                    let messageStore = MessagingStore(
                        localAddress: try ProtocolAddress(
                            name: loggedInUser.userName,
                            deviceId: UInt32(loggedInUser.deviceId))
                    )
                    let messages = try messageStore.getMessageSummary()
                    self.receivingMessageArray = messages
                    updateLabels()
                } catch {
                    DispatchQueue.main.async {
                        print(error)
                        
                        appState.displayedError = IdentifiableError(error as! LocalizedError)
                    }
                }
                
            }
        }
    }
    
    func deleteMessage(_ offsets: IndexSet) {
        let messagesToDelete = offsets.map({ self.receivingMessageArray[$0] })
        
        guard let messagingController = appState.messagingController else {
            appState.displayedError = IdentifiableError(ListViewErrors.noUserLoggedIn)
            return
        }
        
        do {
            for message in messagesToDelete {
                try messagingController.handleDeleteMessageLocally(sender: message.sender)
                receivingMessageArray.remove(atOffsets: offsets)
            }
            updateLabels()
        } catch {
            appState.displayedError = IdentifiableError(error as! LocalizedError)
        }
    }
    
    func deleteLiveMessage(_ offsets: IndexSet) {
        let liveMessagesToDelete = offsets.map({ self.sendingMessageArray[$0] })
        
        guard let messagingController = appState.messagingController else {
            appState.displayedError = IdentifiableError(ListViewErrors.noUserLoggedIn)
            return
        }
        
        do {
            for message in liveMessagesToDelete {
                try messagingController.removeLiveMessageRecipient(recipientAddress: message.recipient)
                sendingMessageArray.remove(atOffsets: offsets)
            }
            updateLabels()
        } catch {
            appState.displayedError = IdentifiableError(error as! LocalizedError)
        }
    }
    
    var body: some View {
        ListView(
            receivingMessageArray: $receivingMessageArray,
            sendingMessageArray: $sendingMessageArray,
            getMessagesInProgress: $getMessagesInProgress,
            loggedInUser: $appState.loggedInUser,
            directionLabels: $directionLabels,
            performSync: performSync,
            deleteLiveMessage: deleteLiveMessage,
            deleteMessage: deleteMessage
        ).onAppear() {
            getStoredMessages()
            performSync()
        }
    }
}
