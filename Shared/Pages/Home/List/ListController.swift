//
//  List Controller.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 08/12/2020.
//

import SwiftUI

struct ListController: View {
    
    @EnvironmentObject var appState: AppState
    
    @State var recieivingMessageArray: [ShortLocationMessage] = []
    @State var sendingMessageArray: [LiveMessage] = []
    @State var getMessagesInProgress: Bool = false
    
    func getStoredMessages() {
        
        guard let loggedInUser = appState.loggedInUser else {
            appState.displayedError = IdentifiableError(ListViewErrors.noUserLoggedIn)
            return
        }
        
        guard let address = try? ProtocolAddress(name: loggedInUser.userName, deviceId: UInt32(loggedInUser.deviceId ?? 1)) else {
            appState.displayedError = IdentifiableError(ListViewErrors.noUserLoggedIn)
            return
        }
        
        let messageStore = MessagingStore(localAddress: address)
        
        do {
            self.recieivingMessageArray = try messageStore.getMessageSummary()
            self.sendingMessageArray = try messageStore.getLiveMessages()
        } catch {
            appState.displayedError = IdentifiableError(ListViewErrors.unableToRetrieveMessages)
        }
        
        
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
        
        messagingController.getMessages(serverAddress: loggedInUser.serverAddress, authToken: loggedInUser.authCode) {
            getMessagesOutcome in
            switch getMessagesOutcome {
            case .failure(let error):
                appState.displayedError = IdentifiableError(error)
            case .success():
                
                do {
                    let messageStore = MessagingStore(
                        localAddress: try ProtocolAddress(
                            name: loggedInUser.userName,
                            deviceId: UInt32(loggedInUser.deviceId ?? 1))
                    )
                    let messages = try messageStore.getMessageSummary()
                    print(messages)
                    self.recieivingMessageArray.append(contentsOf: messages)
                } catch {
                    appState.displayedError = IdentifiableError(error)
                }
                
            }
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
        } catch {
            appState.displayedError = IdentifiableError(error)
        }
        
    }
    
    var body: some View {
        ListView(
            recieivingMessageArray: $recieivingMessageArray,
            sendingMessageArray: $sendingMessageArray,
            getMessagesInProgress: $getMessagesInProgress,
            isSubscriber: appState.loggedInUser?.isSubscriber ?? false,
            performSync: performSync,
            deleteLiveMessage: deleteLiveMessage
        ).onAppear() {
            getStoredMessages()
            performSync()
        }
    }
}
