//
//  ListView.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 08/12/2020.
//

import SwiftUI

struct ListView: View {
    
    @Binding var messageArray: [ShortLocationMessage]
    @Binding var getMessagesInProgress: Bool
               
    var performSync: () -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                if messageArray.count == 0 {
                    HStack {
                        Spacer()
                        Text("No locations received yet").padding()
                        Spacer()
                    }
                }
                List(messageArray) { message in
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
        }
    }
}

struct ListView_Previews: PreviewProvider {
    
    static var previews: some View {
        PreviewWrapper().previewDisplayName("Full Set")
    }
    
    struct PreviewWrapper: View {
        
        @State var messageArray: [ShortLocationMessage] = []
        @State var getMessagesInProgress: Bool = false
                   
        func performSync() {}

        var body: some View {
            return ListView(
                messageArray: $messageArray,
                getMessagesInProgress: $getMessagesInProgress,
                performSync: performSync
            )
        }
    }
    
}

