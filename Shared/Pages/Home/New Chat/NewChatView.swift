//
//  NewChatView.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 08/12/2020.
//

import SwiftUI

struct NewChatView: View {
    
    @Binding var recipientEmail: String
    @Binding var recipientEmailInvalid: Bool
    @Binding var sendLocationInProgress: Bool
    
    var performMessageSend: () -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                TextFieldWithTitleAndValidation(
                    title: "Recipient's Email",
                    invalidText: "Invalid email",
                    validRegex: "^([a-zA-Z0-9_\\-\\.]+)@([a-zA-Z0-9_\\-\\.]+)\\.([a-zA-Z]{2,5})$",
                    disableAutocorrection: true,
                    text: $recipientEmail,
                    showInvalidText: $recipientEmailInvalid
                )
                Button(action: self.performMessageSend) {
                    HStack {
                        if (self.sendLocationInProgress) {
                            ActivityIndicator(isAnimating: true)
                        }
                        Text("Send")
                    }
                }
                .disabled(recipientEmailInvalid || sendLocationInProgress)
                .buttonStyle(RoundedButtonStyle(backgroundColor: Color("AccentColor")))
                .navigationTitle("Send Location")
            }
        }
    }
}

struct NewChatView_Previews: PreviewProvider {
    
    static var previews: some View {
        return Group {
            PreviewWrapper()
        }
    }
    
    struct PreviewWrapper: View {
        
        @State var recipientEmail: String = ""
        @State var recipientEmailInvalid: Bool = false
        @State var sendLocationInProgress: Bool = false
        
        func performMessageSend() {}

        var body: some View {
            
            return NewChatView(
                recipientEmail: $recipientEmail,
                recipientEmailInvalid: $recipientEmailInvalid,
                sendLocationInProgress: $sendLocationInProgress,
                performMessageSend: performMessageSend
            )
        }
    }
    
}
