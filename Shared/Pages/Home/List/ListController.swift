//
//  List Controller.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 08/12/2020.
//

import SwiftUI

struct ListController: View {
    
    @EnvironmentObject var appState: AppState
    
    @State var messageArray: [ShortLocationMessage] = []
    @State var getMessagesInProgress: Bool = false
    
    var messagingController = MessagingController()
    
    func performSync() {
        getMessagesInProgress = true
        
        guard let loggedInUser = appState.loggedInUser else {
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
                    self.messageArray.append(contentsOf: messages)
                } catch {
                    appState.displayedError = IdentifiableError(error)
                }
                
            }
        }
    }
    
    var body: some View {
        ListView(
            messageArray: $messageArray,
            getMessagesInProgress: $getMessagesInProgress,
            performSync: performSync
        ).onAppear() { performSync() }
    }
}
