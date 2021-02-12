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
    @Binding var directionLabels: [String]
    @Binding var isSubscribed: Bool
    @Binding var selectedDirection: Int
               
    var performSync: () -> Void
    var displayError: (LocalizedError) -> Void
    var deleteLiveMessage: (IndexSet) -> Void
    var deleteMessage: (IndexSet) -> Void
    var handleConsentToNewIdentity: (ProtocolAddress) -> Void
    
    var calculatedSendingX: CGFloat {
        let width = UIScreen.main.bounds.size.width
        if selectedDirection == 1 {
            return 0
        } else {
            return width
        }
    }
    
    var calculatedReceivedX: CGFloat {
        let width = UIScreen.main.bounds.size.width
        if selectedDirection == 0 {
            return 0
        } else {
            return -width
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    ZStack {
                        Text("Received")
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                            .padding(.top, 10)
                            .padding(.leading)
                            .offset(x: calculatedReceivedX)
                        Text("Sending")
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                            .padding(.top, 10)
                            .padding(.leading)
                            .offset(x: calculatedSendingX)
                    }
                    Spacer()
                }
                if (isSubscribed) {
                    Picker(selection: $selectedDirection.animation(), label: Text("Please choose a direction")) {
                        ForEach(0 ..< directionLabels.count) {
                            Text(self.directionLabels[$0])
                        }
                    }.pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                }
                ZStack {
                    ReceivingList(
                        receivingMessageArray: $receivingMessageArray,
                        getMessagesInProgress: $getMessagesInProgress,
                        updateIdentityInProgress: $updateIdentityInProgress,
                        deleteMessage: deleteMessage,
                        performSync: performSync,
                        handleConsentToNewIdentity: handleConsentToNewIdentity)
                        .offset(x: calculatedReceivedX)
                    SendingList(
                        sendingMessageArray: $sendingMessageArray,
                        updateIdentityInProgress: $updateIdentityInProgress,
                        deleteLiveMessage: deleteLiveMessage,
                        handleConsentToNewIdentity: handleConsentToNewIdentity,
                        displayError: displayError)
                        .offset(x: calculatedSendingX)
                    
                }
            }.navigationBarHidden(true)
        }
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
        @State var directionLabels = ["Receiving", "Sending"]
        @State var selectedDirection: Int = 0
        @State var isSubscribed: Bool
                   
        func performSync() {}
        func deleteLiveMessage(_: IndexSet) {}
        func deleteMessage(_: IndexSet) {}
        func handleConsentToNewIdentity(_: ProtocolAddress) {}
        func displayError(_: LocalizedError) {}
        
        init(isSubscriber: Bool = false, isEmpty: Bool = false) {
            _isSubscribed = State(initialValue: isSubscriber)
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
                directionLabels: $directionLabels,
                isSubscribed: $isSubscribed,
                selectedDirection: $selectedDirection,
                performSync: performSync,
                displayError: displayError,
                deleteLiveMessage: deleteLiveMessage,
                deleteMessage: deleteMessage,
                handleConsentToNewIdentity: handleConsentToNewIdentity
            )
        }
    }
    
}

