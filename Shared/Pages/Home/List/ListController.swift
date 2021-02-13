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
    @State var updateIdentityInProgress: ProtocolAddress? = nil
    @State var directionLabels = ["Receiving (0)", "Sending (0)"]
    @State var selectedDirection: Int = 0
    @State var isSubscribed = false //Necessary for updates
    
    func updateLabels() {
        print("updateLabels")
        directionLabels[0] = "Receiving (\(self.receivingMessageArray.count))"
        directionLabels[1] = "Sending (\(self.sendingMessageArray.count))"
    }
    
    func getStoredMessages() {
        
        //Updates occur when we have just logged out, stop this
        guard let _ = appState.loggedInUser else {
            return
        }
        
        guard let messagingController = appState.messagingController else {
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
        
        guard let loggedInUser = appState.loggedInUser else {
            return
        }
        
        guard let messagingController = appState.messagingController else {
            return
        }
        
        withAnimation {
            getMessagesInProgress = true
        }
        
        messagingController.getMessages(serverAddress: loggedInUser.serverAddress, authToken: loggedInUser.authCode) { getMessagesOutcome in
            
            withAnimation {
                getMessagesInProgress = false
            }
            
            switch getMessagesOutcome {
            case .failure(let error):
                DispatchQueue.main.async {
                    appState.displayedError = IdentifiableError(error)
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
    
    func handleConsentToNewIdentity(address: ProtocolAddress) {
        
        guard let loggedInUser = appState.loggedInUser else {
            appState.displayedError = IdentifiableError(ListViewErrors.noUserLoggedIn)
            return
        }
        
        guard let messagingController = appState.messagingController else {
            appState.displayedError = IdentifiableError(ListViewErrors.noUserLoggedIn)
            return
        }
            
        updateIdentityInProgress = address
        
        messagingController.updateIdentity(address: address, serverAddress: loggedInUser.serverAddress, authToken: loggedInUser.authCode) { updateIdentityOutcome in
            updateIdentityInProgress = nil
            switch updateIdentityOutcome {
            case .success:
                performSync()
            case .failure(let error):
                appState.displayedError = IdentifiableError(error)
            }
        }
    }
    
    func displayError(error: LocalizedError) {
        appState.displayedError = IdentifiableError(error)
    }
    
    var body: some View {
        ListView(
            receivingMessageArray: $receivingMessageArray,
            sendingMessageArray: $sendingMessageArray,
            getMessagesInProgress: $getMessagesInProgress,
            updateIdentityInProgress: $updateIdentityInProgress,
            directionLabels: $directionLabels,
            isSubscribed: $isSubscribed,
            selectedDirection: $selectedDirection,
            performSync: performSync,
            displayError: displayError,
            deleteLiveMessage: deleteLiveMessage,
            deleteMessage: deleteMessage,
            handleConsentToNewIdentity: handleConsentToNewIdentity
        ).onAppear() {
            if let loggedInUser = appState.loggedInUser {
                if loggedInUser.subscriptionExpiryDate == nil {
                    self.selectedDirection = 0
                } else {
                    self.isSubscribed = true
                }
            }
            getStoredMessages()
            performSync()
        }
        .onReceive(NotificationCenter.default.publisher(for: .subscriptionController_SubscriptionVerified), perform: {_ in
            withAnimation {
                self.isSubscribed = true
            }
        })
        .onReceive(NotificationCenter.default.publisher(for: .subscriptionController_SubscriptionFailed), perform: {_ in
            withAnimation {
                self.isSubscribed = false
                self.selectedDirection = 0
            }
        })
        .onReceive(NotificationCenter.default.publisher(for: .messagingStore_LiveMessagesUpdates), perform: { _ in
            getStoredMessages()
        })
    }
}
