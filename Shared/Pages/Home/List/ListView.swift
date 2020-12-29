//
//  ListView.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 08/12/2020.
//

import SwiftUI

struct ListView: View {
    
    @Binding var recieivingMessageArray: [ShortLocationMessage]
    @Binding var sendingMessageArray: [ProtocolAddress]
    @Binding var getMessagesInProgress: Bool
    @State private var selectedDirection = 0
    
    var isSubscriber: Bool
    var directions = ["Receiving", "Sending"]
               
    var performSync: () -> Void
    
    var body: some View {
        NavigationView {
            if isSubscriber {
                Picker(selection: $selectedDirection, label: Text("Please choose a direction")) {
                    ForEach(0 ..< directions.count) {
                        Text(self.directions[$0])
                    }
                }.pickerStyle(SegmentedPickerStyle())
            }
            if selectedDirection == 0 {
                VStack {
                    if recieivingMessageArray.count == 0 {
                        HStack {
                            Spacer()
                            Text("No locations received yet").padding()
                            Spacer()
                        }
                    }
                    List(recieivingMessageArray) { message in
                        NavigationLink(destination: DetailController(sender: message.sender)) {
                            HStack {
                                Text(message.sender.combinedValue)
                                Spacer()
                                Text(String(message.lastReceived))
                            }
                        }
                    }
                    Button(action: self.performSync) {
                        HStack {
                            if (self.getMessagesInProgress) {
                                ActivityIndicator(isAnimating: true)
                            }
                            Text("Sync")
                        }
                    }
                    .disabled(getMessagesInProgress)
                    .buttonStyle(RoundedButtonStyle(backgroundColor: Color("AccentColor")))
                    .navigationTitle("Received")
                }
            } else {
                VStack {
                    
                }
            }
        }
    }
}

struct ListView_Previews: PreviewProvider {
    
    static var previews: some View {
        PreviewWrapper().previewDisplayName("Full Set")
    }
    
    struct PreviewWrapper: View {
        
        @State var receivingMessageArray: [ShortLocationMessage] = []
        @State var sendingMessageArray: [ProtocolAddress] = []
        @State var getMessagesInProgress: Bool = false
                   
        func performSync() {}

        var body: some View {
            return ListView(
                recieivingMessageArray: $receivingMessageArray,
                sendingMessageArray: $sendingMessageArray,
                getMessagesInProgress: $getMessagesInProgress,
                isSubscriber: false,
                performSync: performSync
            )
        }
    }
    
}

