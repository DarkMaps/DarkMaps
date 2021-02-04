//
//  ListView.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 08/12/2020.
//

import SwiftUI

struct ListView: View {
    
    @Binding var receivingMessageArray: [ShortLocationMessage]
    @Binding var sendingMessageArray: [LiveMessage]
    @Binding var getMessagesInProgress: Bool
    @Binding var updateIdentityInProgress: ProtocolAddress?
    @Binding var loggedInUser: LoggedInUser?
    @Binding var directionLabels: [String]
    
    @State private var selectedDirection = 0
               
    var performSync: () -> Void
    var deleteLiveMessage: (IndexSet) -> Void
    var deleteMessage: (IndexSet) -> Void
    var handleConsentToNewIdentity: (ProtocolAddress) -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                if (loggedInUser?.subscriptionExpiryDate != nil) {
                    Picker(selection: $selectedDirection, label: Text("Please choose a direction")) {
                        ForEach(0 ..< directionLabels.count) {
                            Text(self.directionLabels[$0])
                        }
                    }.pickerStyle(SegmentedPickerStyle())
                }
                if selectedDirection == 0 {
                    ReceivingList(
                        receivingMessageArray: $receivingMessageArray,
                        getMessagesInProgress: $getMessagesInProgress,
                        updateIdentityInProgress: $updateIdentityInProgress,
                        deleteMessage: deleteMessage,
                        performSync: performSync,
                        handleConsentToNewIdentity: handleConsentToNewIdentity)
                } else {
                    SendingList(
                        sendingMessageArray: $sendingMessageArray,
                        updateIdentityInProgress: $updateIdentityInProgress,
                        deleteLiveMessage: deleteLiveMessage,
                        handleConsentToNewIdentity: handleConsentToNewIdentity)
                }
            }.navigationTitle("Received")
            
        }
        .padding(.bottom, 0)
        .onAppear(perform: {
            if let loggedInUser = self.loggedInUser {
                if loggedInUser.subscriptionExpiryDate == nil {
                    self.selectedDirection = 0
                }
            }
        })
    }
}

struct ListView_Previews: PreviewProvider {
    
    static var previews: some View {
        Group {
            PreviewWrapper(isSubscriber: true).previewDisplayName("Subscriber")
            PreviewWrapper(isSubscriber: false).previewDisplayName("Not Subscriber")
            PreviewWrapper(isSubscriber: false, isEmpty: true).previewDisplayName("Empty List")
            PreviewWrapper(isSubscriber: false, isEmpty: true).previewDevice("iPod touch (7th generation)").previewDisplayName("Empty List")
        }
    }
    
    struct PreviewWrapper: View {
        
        @State var receivingMessageArray: [ShortLocationMessage] =
            [
                ShortLocationMessage(
                    LocationMessage(
                        id: 1,
                        sender: try! ProtocolAddress(
                            name: "test@test.com",
                            deviceId: UInt32(1)),
                        location: Location(
                            latitude: 1,
                            longitude: 1,
                            liveExpiryDate: Date().addingTimeInterval(-300000),
                            time: Date().addingTimeInterval(-3000)
                        )
                    )
                ),
                ShortLocationMessage(
                    LocationMessage(
                        id: 2,
                        sender: try! ProtocolAddress(
                            name: "test2@test.com",
                            deviceId: UInt32(1)),
                        location: Location(
                            latitude: 1,
                            longitude: 1,
                            time: Date().addingTimeInterval(-1000)
                        )
                    )
                ),
                ShortLocationMessage(
                    LocationMessage(
                        id: 3,
                        sender: try! ProtocolAddress(
                            name: "test3@test.com",
                            deviceId: UInt32(1)),
                        error: .badResponseFromServer
                    )
                ),
                ShortLocationMessage(
                    LocationMessage(
                        id: 4,
                        sender: try! ProtocolAddress(
                            name: "test4@test.com",
                            deviceId: UInt32(1)),
                        error: .alteredIdentity
                    )
                )
            ]
        @State var sendingMessageArray: [LiveMessage] = [
            LiveMessage(
                recipient: try! ProtocolAddress(
                    name: "test1@test.com",
                    deviceId: UInt32(1)),
                expiry: Date().addingTimeInterval(3000)),
            LiveMessage(
                recipient: try! ProtocolAddress(
                    name: "test2@test.com",
                    deviceId: UInt32(1)),
                expiry: Date().addingTimeInterval(2000),
                error: MessagingControllerError.unableToSendMessage),
            LiveMessage(
                recipient: try! ProtocolAddress(
                    name: "test3@test.com",
                    deviceId: UInt32(1)),
                expiry: Date().addingTimeInterval(1000),
                error: MessagingControllerError.alteredIdentity)
        ]
        @State var getMessagesInProgress: Bool = false
        @State var updateIdentityInProgress: ProtocolAddress? = nil
        @State var loggedInUser: LoggedInUser?
        @State var directionLabels = ["Receiving", "Sending"]
                   
        func performSync() {}
        func deleteLiveMessage(_: IndexSet) {}
        func deleteMessage(_: IndexSet) {}
        func handleConsentToNewIdentity(_: ProtocolAddress) {}
        
        init(isSubscriber: Bool = false, isEmpty: Bool = false) {
            let loggedInUser = LoggedInUser(
                userName: "test@test.com",
                deviceId: 1,
                serverAddress: "test.com",
                authCode: "testAuthCode",
                is2FAUser: false,
                subscriptionExpiryDate: isSubscriber ? Date() : nil)
            _loggedInUser = State(initialValue: loggedInUser)
            if (isEmpty) {
                _receivingMessageArray = State(initialValue: [])
            }
        }

        var body: some View {
            return ListView(
                receivingMessageArray: $receivingMessageArray,
                sendingMessageArray: $sendingMessageArray,
                getMessagesInProgress: $getMessagesInProgress,
                updateIdentityInProgress: $updateIdentityInProgress,
                loggedInUser: $loggedInUser,
                directionLabels: $directionLabels,
                performSync: performSync,
                deleteLiveMessage: deleteLiveMessage,
                deleteMessage: deleteMessage,
                handleConsentToNewIdentity: handleConsentToNewIdentity
            )
        }
    }
    
}

