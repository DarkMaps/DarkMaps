//
//  NewChatController.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 08/12/2020.
//
import SwiftUI
import StoreKit

struct NewChatController: View {
    
    @EnvironmentObject var appState: AppState
    
    @State var recipientEmail: String = ""
    @State var recipientEmailInvalid: Bool = true
    @State var isLiveLocation: Bool = false
    @State var sendLocationInProgress: Bool = false
    @State var selectedLiveLength = 0
    @State var messageSendSuccessAlertShowing = false
    @State var liveMessageSendSuccessAlertShowing = false
    @State var recipientIdentityChangedAlertShowing = false
    @State var invalidEmailAlertShowing = false
    @State var ownEmailAlertShowing = false
    @State var liveLocationOptionsVisible = false
    @State var isSubscribed = false //Necessary for animation
    
    func parseLiveExpiry() -> Date {
        let timeToAdd: Int
        if selectedLiveLength == 0 {
            timeToAdd = 60 * 15
        } else if selectedLiveLength == 1 {
            timeToAdd = 60 * 60
        } else {
            timeToAdd = 60 * 60 * 4
        }
        let now = Date().addingTimeInterval(Double(timeToAdd))
        return now
    }
    
    func performMessageSend() {
        
        let predicate = NSPredicate(format:"SELF MATCHES %@", "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}")
        guard predicate.evaluate(with: recipientEmail) else {
            self.invalidEmailAlertShowing = true
            return
        }
        
        guard let loggedInUser = appState.loggedInUser else {
            appState.displayedError = IdentifiableError(NewChatErrors.noUserLoggedIn)
            return
        }
        
        guard recipientEmail != loggedInUser.userName else {
            self.ownEmailAlertShowing = true
            return
        }
        
        guard let messagingController = appState.messagingController else {
            appState.displayedError = IdentifiableError(ListViewErrors.noUserLoggedIn)
            return
        }
        
        sendLocationInProgress = true
        
        // Even if this is a live message send one normal message first to ensure successful
        appState.locationController.getCurrentLocation() {
            getLocationOutcome in
            
            switch getLocationOutcome {
            case .failure(let error):
                appState.displayedError = IdentifiableError(error)
                sendLocationInProgress = false
            case .success(var location):
                
                if isLiveLocation {
                    location.liveExpiryDate = parseLiveExpiry()
                }
                
                messagingController.sendMessage(
                    recipientName: recipientEmail,
                    recipientDeviceId: Int(1),
                    message: location,
                    serverAddress: loggedInUser.serverAddress,
                    authToken: loggedInUser.authCode) {
                    sendMessageOutcome in
                    
                    switch sendMessageOutcome {
                    case .failure(let error):
                        sendLocationInProgress = false
                        if error == .alteredIdentity {
                            recipientIdentityChangedAlertShowing = true
                        } else {
                            appState.displayedError = IdentifiableError(error)
                        }
                    case .success():
                        
                        // If successful and live message add to stored live messages
                        if isLiveLocation {
                            do {
                                try messagingController.addLiveMessage(recipientName: recipientEmail, recipientDeviceId: Int(1), expiry: parseLiveExpiry())
                                sendLocationInProgress = false
                                liveMessageSendSuccessAlertShowing = true
                            } catch {
                                appState.displayedError = IdentifiableError(error as! LocalizedError)
                                sendLocationInProgress = false
                            }
                        } else {
                            messageSendSuccessAlertShowing = true
                            sendLocationInProgress = false
                        }
                    }
                }
            }
        }
        
    }
    
    func handleConsentToNewIdentity() {
        
        sendLocationInProgress = true
        
        guard let loggedInUser = appState.loggedInUser else {
            appState.displayedError = IdentifiableError(ListViewErrors.noUserLoggedIn)
            return
        }
        
        guard let messagingController = appState.messagingController else {
            appState.displayedError = IdentifiableError(ListViewErrors.noUserLoggedIn)
            return
        }
        
        guard let address = try? ProtocolAddress(name: recipientEmail, deviceId: 1) else {
            appState.displayedError = IdentifiableError(ListViewErrors.noUserLoggedIn)
            return
        }
        
        messagingController.updateIdentity(address: address, serverAddress: loggedInUser.serverAddress, authToken: loggedInUser.authCode) { updateIdentityOutcome in
            sendLocationInProgress = false
            switch updateIdentityOutcome {
            case .success:
                performMessageSend()
            case .failure(let error):
                appState.displayedError = IdentifiableError(error)
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
                liveLocationOptionsVisible: $liveLocationOptionsVisible,
                isSubscribed: $isSubscribed,
                performMessageSend: performMessageSend
            )
            .onReceive(NotificationCenter.default.publisher(for: .subscriptionController_SubscriptionVerified), perform: {_ in
                withAnimation {
                    self.isSubscribed = true
                }
            })
            .onAppear(perform: {
                guard let loggedInUser = appState.loggedInUser else {
                    return
                }
                if loggedInUser.subscriptionExpiryDate != nil {
                    self.isSubscribed = true
                }
            })
            Text("").hidden().alert(isPresented: $recipientIdentityChangedAlertShowing) {
                Alert(
                    title: Text("Identity Changed"),
                    message: Text("\(recipientEmail) identity has changed since you last communicated with them. Are you happy to send your location to their new identity?"),
                    primaryButton: Alert.Button.default(Text("Yes"), action: handleConsentToNewIdentity),
                    secondaryButton: Alert.Button.cancel()
                )
            }
            Text("").hidden().alert(isPresented: $messageSendSuccessAlertShowing) {
                Alert(
                    title: Text("Success"),
                    message: Text("The message was sent successfully."),
                    dismissButton: .default(Text("OK"), action: {recipientEmail = ""})
                )
            }
            Text("").hidden().alert(isPresented: $liveMessageSendSuccessAlertShowing) {
                Alert(
                    title: Text("Success"),
                    message: Text("You are now broadcasting your location to \(recipientEmail)."),
                    dismissButton: .default(Text("OK"), action: {recipientEmail = ""})
                )
            }
            Text("").hidden().alert(isPresented: $invalidEmailAlertShowing) {
                Alert(
                    title: Text("Error"),
                    message: Text("Please enter a valid email."),
                    dismissButton: .cancel()
                )
            }
            Text("").hidden().alert(isPresented: $ownEmailAlertShowing) {
                Alert(
                    title: Text("Error"),
                    message: Text("You cannot send messages to yourself."),
                    dismissButton: .cancel()
                )
            }
        }
    }
}
