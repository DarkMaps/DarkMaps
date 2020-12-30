//
//  NewChatController.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 08/12/2020.
//
import SwiftUI

struct NewChatController: View {
    
    @EnvironmentObject var appState: AppState
    
    let locationController = LocationController()
    
    @State var recipientEmail: String = ""
    @State var recipientEmailInvalid: Bool = false
    @State var isLiveLocation: Bool = false
    @State var sendLocationInProgress: Bool = false
    @State var selectedLiveLength = 0
    
    func parseLiveLengthExpiry() -> Int {
        let timeToAdd: Int
        if selectedLiveLength == 0 {
            timeToAdd = 60 * 15
        } else if selectedLiveLength == 1 {
            timeToAdd = 60 * 60
        } else {
            timeToAdd = 60 * 60 * 4
        }
        let now = Date().timeIntervalSinceNow
        return Int(now) + timeToAdd
    }
    
    func performMessageSend() {
        
        guard let loggedInUser = appState.loggedInUser else {
            appState.displayedError = IdentifiableError(NewChatErrors.noUserLoggedIn)
            return
        }
        
        guard let messagingController = appState.messagingController else {
            appState.displayedError = IdentifiableError(ListViewErrors.noUserLoggedIn)
            return
        }
        
        sendLocationInProgress = true
        
        if isLiveLocation {
            
            do {
                try messagingController.addLiveMessage(recipientName: recipientEmail, recipientDeviceId: Int(1), expiry: parseLiveLengthExpiry())
                sendLocationInProgress = false
            } catch {
                appState.displayedError = IdentifiableError(error)
                sendLocationInProgress = false
            }
            
            
        } else {
            
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
    }
    
    var body: some View {
        ZStack {
            NewChatView(
                recipientEmail: $recipientEmail,
                recipientEmailInvalid: $recipientEmailInvalid,
                sendLocationInProgress: $sendLocationInProgress,
                isLiveLocation: $isLiveLocation,
                selectedLiveLength: $selectedLiveLength,
                isSubscriber: appState.loggedInUser?.subscriptionExpiryDate != nil,
                performMessageSend: performMessageSend
            )
        }
    }
}
