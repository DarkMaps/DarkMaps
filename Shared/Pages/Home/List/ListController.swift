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
    @State var sendingMessageArray: [ProtocolAddress] = []
    @State var getMessagesInProgress: Bool = false
    
    func performSync() {
        getMessagesInProgress = true
        
        guard let loggedInUser = appState.loggedInUser else {
            appState.displayedError = IdentifiableError(ListViewErrors.noUserLoggedIn)
            return
        }
        
        guard let messagingController = try? MessagingController(userName: loggedInUser.userName) else {
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
    
    var body: some View {
        ListView(
            recieivingMessageArray: $recieivingMessageArray,
            sendingMessageArray: $sendingMessageArray,
            getMessagesInProgress: $getMessagesInProgress,
            isSubscriber: appState.loggedInUser?.isSubscriber ?? false,
            performSync: performSync
        ).onAppear() { performSync() }
    }
}
