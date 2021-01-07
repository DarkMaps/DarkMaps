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
            List {
                ForEach(sendingMessageArray, id: \.id) { message in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(message.recipient.name)
                            if message.error != nil {
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
                }
                .onDelete(perform: deleteLiveMessage)
                if sendingMessageArray.count == 0 {
                    HStack {
                        Spacer()
                        Text("Not sending location to anyone").padding()
                        Spacer()
                    }
                }
            }
        }
    }
}
