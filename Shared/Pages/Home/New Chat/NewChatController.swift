//
//  NewChatController.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 08/12/2020.
//
import SwiftUI

struct NewChatController: View {
    
    @EnvironmentObject var appState: AppState
    
    let messagingController = MessagingController()
    let locationController = LocationController()
    
    @State var recipientEmail: String = ""
    @State var recipientEmailInvalid: Bool = false
    @State var isLiveLocation: Bool = false
    @State var sendLocationInProgress: Bool = false
    
    func performMessageSend() {
        
        guard let loggedInUser = appState.loggedInUser else {
            appState.displayedError = IdentifiableError(NewChatErrors.noUserLoggedIn)
            return
        }
        
        sendLocationInProgress = true
        
        locationController.getCurrentLocation() {
            getLocationOutcome in
            
            switch getLocationOutcome {
            case .failure(let error):
                appState.displayedError = IdentifiableError(error)
                sendLocationInProgress = false
            case .success(let location):
                
                messagingController.sendMessage(
                    recipientName: recipientEmail,
                    recipientDeviceId: Int(1),
                    message: location,
                    serverAddress: loggedInUser.serverAddress,
                    authToken: loggedInUser.serverAddress) {
                    sendMessageOutcome in
                    
                    switch sendMessageOutcome {
                    case .failure(let error):
                        appState.displayedError = IdentifiableError(error)
                        sendLocationInProgress = false
                    case .success():
                        recipientEmail = ""
                        sendLocationInProgress = false
                    }
                }
            }
        }
    }
    
    var body: some View {
        ZStack {
            NewChatView(
                recipientEmail: $recipientEmail,
                recipientEmailInvalid: $recipientEmailInvalid,
                sendLocationInProgress: $sendLocationInProgress,
                isLiveLocation: $isLiveLocation,
                isSubscriber: appState.loggedInUser?.isSubscriber ?? false,
                performMessageSend: performMessageSend
            )
        }
    }
}
