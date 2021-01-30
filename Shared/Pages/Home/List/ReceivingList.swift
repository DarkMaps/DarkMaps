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
    @Binding var updateIdentityInProgress: ProtocolAddress?
    
    @State var acceptAlteredIdentityAlertRelatesTo: ProtocolAddress? = nil
    
    var deleteMessage: (IndexSet) -> Void
    var performSync: () -> Void
    var handleConsentToNewIdentity: (ProtocolAddress) -> Void
    
    var body: some View {
        VStack {
            List {
                ForEach(receivingMessageArray, id: \.id) { message in
                    if !message.isAlteredIdentity {
                        NavigationLink(destination: DetailController(sender: message.sender)) {
                            ReceivingObject(updateIdentityInProgress: $updateIdentityInProgress, receivedMessage: message)
                        }.padding()
                    } else {
                        ReceivingObject(updateIdentityInProgress: $updateIdentityInProgress, receivedMessage: message)
                            .padding()
                            .onTapGesture {
                                self.acceptAlteredIdentityAlertRelatesTo = message.sender
                            }
                    }
                    
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
            .buttonStyle(RoundedButtonStyle(backgroundColor: Color("AccentColor"), padded: true))
            .background(
                Text("").hidden().alert(item: $acceptAlteredIdentityAlertRelatesTo, content: {chosenSender in
                    Alert(title:
                            Text("Altered Identity"),
                          message: Text("\(chosenSender.name)'s identity has changed, do you wish to use their new identity?"),
                          primaryButton: Alert.Button.destructive(
                            Text("OK"),
                            action: {
                                handleConsentToNewIdentity(chosenSender)
                            }),
                          secondaryButton: Alert.Button.cancel())
                })
            )
        }
    }
}

struct ReceivingObject: View {
    
    @Binding var updateIdentityInProgress: ProtocolAddress?
    
    var receivedMessage: ShortLocationMessage
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(receivedMessage.sender.name)
                if updateIdentityInProgress == receivedMessage.sender {
                    HStack {
                        ActivityIndicator(isAnimating: true)
                        Text("Updating Identity.")
                            .italic()
                            .foregroundColor(.accentColor)
                            .font(.footnote)
                    }
                } else if receivedMessage.isAlteredIdentity {
                    Text("Altered Identity").italic().foregroundColor(.accentColor)
                        .font(.footnote)
                } else if receivedMessage.isError {
                    Text("Error").italic().foregroundColor(.red)
                        .font(.footnote)
                } else {
                    Text(receivedMessage.relativeDate)
                        .italic()
                        .font(.footnote)
                }
            }
            Spacer()
            if receivedMessage.isLive {
                Image(systemName: "bolt.fill").foregroundColor(.yellow)
            }
            
        }
    }
}
