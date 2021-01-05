//
//  SendingList.swift
//  DarkMaps (iOS)
//
//  Created by Matthew Roche on 05/01/2021.
//

import SwiftUI

struct SendingList: View {
    
    @Binding var sendingMessageArray: [LiveMessage]
    
    var deleteLiveMessage: (IndexSet) -> Void
    
    var body: some View {
        VStack {
            if sendingMessageArray.count == 0 {
                HStack {
                    Spacer()
                    Text("Not sending location to anyone").padding()
                    Spacer()
                }
            }
            List {
                ForEach(sendingMessageArray, id: \.id) { message in
                    HStack {
                        Text(message.recipient.combinedValue)
                        Spacer()
                        if Double(message.expiry) < Date().timeIntervalSince1970 {
                            Text("Expired")
                        } else {
                            Text(message.humanReadableExpiry)
                        }
                    }
                }
                .onDelete(perform: deleteLiveMessage)
            }
        }
    }
}
