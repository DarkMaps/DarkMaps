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
    @State var recipientEmailInvalid: Bool = false
    @State var isLiveLocation: Bool = false
    @State var sendLocationInProgress: Bool = false
    @State var selectedLiveLength = 0
    @State var messageSendSuccessAlertShowing = false
    @State var liveMessageSendSuccessAlertShowing = false
    @State var subscribeInProgress = false
    @State var subscriptionOptions: [SKProduct] = []
    @State var subscriptionOptionsSheetShowing = false
    @State var isSubscribed = false //Necessary for animation
    
    var subscriptionController = SubscriptionController()
    
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
                try messagingController.addLiveMessage(recipientName: recipientEmail, recipientDeviceId: Int(1), expiry: parseLiveExpiry())
                sendLocationInProgress = false
                liveMessageSendSuccessAlertShowing = true
            } catch {
                appState.displayedError = IdentifiableError(error)
                sendLocationInProgress = false
            }
            
            
        } else {
            
            appState.locationController.getCurrentLocation() {
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
                        authToken: loggedInUser.authCode) {
                        sendMessageOutcome in
                        
                        switch sendMessageOutcome {
                        case .failure(let error):
                            appState.displayedError = IdentifiableError(error)
                            sendLocationInProgress = false
                        case .success():
                            messageSendSuccessAlertShowing = true
                            sendLocationInProgress = false
                        }
                    }
                }
            }
            
        }
    }
    
    func getSubscriptionOptions() {
        subscribeInProgress = true
        subscriptionController.getSubscriptions() { result in
            subscribeInProgress = false
            switch result {
            case .success(let options):
                self.subscriptionOptions = options
                self.subscriptionOptionsSheetShowing = true
            case .failure(let error):
                appState.displayedError = IdentifiableError(error)
            }
        }
    }
    
    func subscribe(product: SKProduct) {
        subscribeInProgress = true
        subscriptionController.purchaseSubscription(product: product) { result in
            subscribeInProgress = false
            switch result {
            case .success(let date):
                print(date)
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
                subscribeInProgress: $subscribeInProgress,
                isSubscribed: $isSubscribed,
                performMessageSend: performMessageSend,
                getSubscriptionOptions: getSubscriptionOptions
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
            SubscriptionActionSheet(
                isShowing: $subscriptionOptionsSheetShowing,
                subscriptionOptions: $subscriptionOptions,
                subscribe: subscribe
            )
        }
    }
}
