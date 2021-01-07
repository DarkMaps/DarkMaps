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
    @Binding var loggedInUser: LoggedInUser?
    @State private var selectedDirection = 0
    
    var directions = ["Receiving", "Sending"]
               
    var performSync: () -> Void
    var deleteLiveMessage: (IndexSet) -> Void
    var deleteMessage: (IndexSet) -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                if (loggedInUser?.subscriptionExpiryDate != nil) {
                    Picker(selection: $selectedDirection, label: Text("Please choose a direction")) {
                        ForEach(0 ..< directions.count) {
                            Text(self.directions[$0])
                        }
                    }.pickerStyle(SegmentedPickerStyle())
                }
                if selectedDirection == 0 {
                    ReceivingList(
                        receivingMessageArray: $receivingMessageArray,
                        getMessagesInProgress: $getMessagesInProgress,
                        deleteMessage: deleteMessage,
                        performSync: performSync)
                } else {
                    SendingList(
                        sendingMessageArray: $sendingMessageArray,
                        deleteLiveMessage: deleteLiveMessage)
                }
            }.navigationTitle("Received")
        }
    }
}

struct ListView_Previews: PreviewProvider {
    
    static var previews: some View {
        Group {
            PreviewWrapper(isSubscriber: true).previewDisplayName("Subscriber")
            PreviewWrapper(isSubscriber: false).previewDisplayName("Not Subscriber")
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
                )
            ]
        @State var sendingMessageArray: [LiveMessage] = []
        @State var getMessagesInProgress: Bool = false
        @State var loggedInUser: LoggedInUser?
                   
        func performSync() {}
        func deleteLiveMessage(_: IndexSet) {}
        func deleteMessage(_: IndexSet) {}
        
        init(isSubscriber: Bool = false) {
            let loggedInUser = LoggedInUser(
                userName: "test@test.com",
                deviceId: 1,
                serverAddress: "test.com",
                authCode: "testAuthCode",
                is2FAUser: isSubscriber)
            _loggedInUser = State(initialValue: loggedInUser)
        }

        var body: some View {
            return ListView(
                receivingMessageArray: $receivingMessageArray,
                sendingMessageArray: $sendingMessageArray,
                getMessagesInProgress: $getMessagesInProgress,
                loggedInUser: $loggedInUser,
                performSync: performSync,
                deleteLiveMessage: deleteLiveMessage,
                deleteMessage: deleteMessage
            )
        }
    }
    
}

