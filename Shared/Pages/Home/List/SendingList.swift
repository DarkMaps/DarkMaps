//
//  SendingList.swift
//  DarkMaps (iOS)
//
//  Created by Matthew Roche on 05/01/2021.
//

import SwiftUI

struct SendingList: View {
    
    @Binding var sendingMessageArray: [LiveMessage]
    @Binding var updateIdentityInProgress: ProtocolAddress?
    
    @State var acceptAlteredIdentityAlertRelatesTo: ProtocolAddress? = nil
    
    var deleteLiveMessage: (IndexSet) -> Void
    var handleConsentToNewIdentity: (ProtocolAddress) -> Void
    
    var body: some View {
        VStack {
            List {
                ForEach(sendingMessageArray, id: \.id) { message in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(message.recipient.name)
                            if updateIdentityInProgress == message.recipient {
                                HStack {
                                    ActivityIndicator(isAnimating: true)
                                    Text("Updating Identity.")
                                        .italic()
                                        .foregroundColor(.accentColor)
                                        .font(.footnote)
                                }
                            } else if message.error == .alteredIdentity {
                                Text("Altered Identity. Click to accept.")
                                    .italic()
                                    .foregroundColor(.accentColor)
                                    .font(.footnote)
                            } else if message.error != nil {
                                Text("Error")
                                    .italic()
                                    .foregroundColor(.red)
                                    .font(.footnote)
                            } else {
                                Text(message.humanReadableExpiry)
                                    .italic()
                                    .font(.footnote)
                            }
                        }
                        Spacer()
                        Image(systemName: "bolt").foregroundColor(.yellow)
                    }.padding()
                    .onTapGesture {
                        if updateIdentityInProgress == nil {
                            if message.error == .alteredIdentity {
                                acceptAlteredIdentityAlertRelatesTo = message.recipient
                            }
                        }
                    }
                }
                .onDelete(perform: deleteLiveMessage)
                if sendingMessageArray.count == 0 {
                    HStack {
                        Spacer()
                        Text("Not sending location to anyone").padding()
                        Spacer()
                    }.cornerRadius(10)
                }
            }
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
        }
    }
}
