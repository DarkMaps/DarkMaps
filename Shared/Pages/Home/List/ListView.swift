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
    @State private var selectedDirection = 0
    
    var isSubscriber: Bool
    var directions = ["Receiving", "Sending"]
               
    var performSync: () -> Void
    var deleteLiveMessage: (IndexSet) -> Void
    var deleteMessage: (IndexSet) -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                if isSubscriber {
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
        
        var isSubscriber: Bool
                   
        func performSync() {}
        func deleteLiveMessage(_: IndexSet) {}
        func deleteMessage(_: IndexSet) {}

        var body: some View {
            return ListView(
                receivingMessageArray: $receivingMessageArray,
                sendingMessageArray: $sendingMessageArray,
                getMessagesInProgress: $getMessagesInProgress,
                isSubscriber: isSubscriber,
                performSync: performSync,
                deleteLiveMessage: deleteLiveMessage,
                deleteMessage: deleteMessage
            )
        }
    }
    
}

