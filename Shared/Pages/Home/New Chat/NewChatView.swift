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
    @Binding var isLiveLocation: Bool
    @Binding var selectedLiveLength: Int
    var isSubscriber: Bool
    
    var liveLengths = ["15 Minutes", "1 Hour", "4 Hours"]
    
    var performMessageSend: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                TextFieldWithTitleAndValidation(
                    title: "Recipient's Email",
                    invalidText: "Invalid email",
                    validRegex: "^([a-zA-Z0-9_\\-\\.]+)@([a-zA-Z0-9_\\-\\.]+)\\.([a-zA-Z]{2,5})$",
                    disableAutocorrection: true,
                    text: $recipientEmail,
                    showInvalidText: $recipientEmailInvalid
                ).padding(.horizontal).padding(.top)
                if (!isSubscriber) {
                    Text("Subscribe to enable live location sending")
                        .padding()
                        .background(Color(UIColor(Color.accentColor).withAlphaComponent(0.7)))
                        .cornerRadius(10.0)
                }
                Toggle("Live Location", isOn: $isLiveLocation)
                    .padding(.horizontal)
                    .disabled(!isSubscriber)
                Picker(
                    selection: $selectedLiveLength,
                    label: Text("Broadcast Length")) {
                    ForEach(0 ..< liveLengths.count) {
                       Text(self.liveLengths[$0])
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .disabled(!isSubscriber || !isLiveLocation)
                Button(action: self.performMessageSend) {
                    HStack {
                        if (self.sendLocationInProgress) {
                            ActivityIndicator(isAnimating: true)
                        } else if (self.isLiveLocation) {
                            Image(systemName: "bolt.fill").foregroundColor(.yellow)
                        }
                        Text("Send")
                    }
                }
                .padding(.top)
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
            PreviewWrapper(isSubscriber: true)
            PreviewWrapper(isSubscriber: false)
        }
    }
    
    struct PreviewWrapper: View {
        
        @State var recipientEmail: String = ""
        @State var recipientEmailInvalid: Bool = false
        @State var sendLocationInProgress: Bool = false
        @State var isLiveLocation: Bool = false
        @State var selectedLiveLength = 0
        
        func performMessageSend() {}
        
        var isSubscriber: Bool

        var body: some View {
            
            return NewChatView(
                recipientEmail: $recipientEmail,
                recipientEmailInvalid: $recipientEmailInvalid,
                sendLocationInProgress: $sendLocationInProgress,
                isLiveLocation: $isLiveLocation,
                selectedLiveLength: $selectedLiveLength,
                isSubscriber: isSubscriber,
                performMessageSend: performMessageSend
            )
        }
    }
    
}
