//
//  ReceivingList.swift
//  DarkMaps (iOS)
//
//  Created by Matthew Roche on 05/01/2021.
//

import SwiftUI

struct ReceivingList: View {
    
    @Binding var receivingMessageArray: [ShortLocationMessage]
    @Binding var getMessagesInProgress: Bool
    
    var deleteMessage: (IndexSet) -> Void
    var performSync: () -> Void
    
    var body: some View {
        VStack {
            List {
                ForEach(receivingMessageArray, id: \.id) { message in
                    NavigationLink(destination: DetailController(sender: message.sender)) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(message.sender.name)
                                if message.isError {
                                    Text("Error").italic().foregroundColor(.red)
                                        .font(.footnote)
                                } else {
                                    Text(message.relativeDate)
                                        .italic()
                                        .font(.footnote)
                                }
                            }
                            Spacer()
                            if message.isLive {
                                Image(systemName: "bolt").foregroundColor(.yellow)
                            }
                            
                        }
                    }.padding()
                }
                .onDelete(perform: deleteMessage)
                if receivingMessageArray.count == 0 {
                    HStack {
                        Spacer()
                        Text("No locations received yet").padding()
                        Spacer()
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
        }
    }
}
