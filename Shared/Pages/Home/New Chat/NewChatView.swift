//
//  NewChatView.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 08/12/2020.
//

import SwiftUI

struct NewChatView: View {
    
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var recipientEmail: String
    @Binding var recipientEmailInvalid: Bool
    @Binding var sendLocationInProgress: Bool
    @Binding var isLiveLocation: Bool
    @Binding var selectedLiveLength: Int
    // This is unfortunately necessary for animation
    @Binding var isSubscribed: Bool
    
    var liveLengths = ["15 Minutes", "1 Hour", "4 Hours"]
    
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
                ).padding(.horizontal).padding(.top)
                Toggle("Live Location", isOn: $isLiveLocation)
                    .padding(.horizontal)
                    .disabled(isSubscribed == false)
                Picker(
                    selection: $selectedLiveLength,
                    label: Text("Broadcast Length")) {
                    ForEach(0 ..< liveLengths.count) {
                       Text(self.liveLengths[$0])
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .disabled((isSubscribed == false) || !isLiveLocation)
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
                .disabled(recipientEmailInvalid || sendLocationInProgress || recipientEmail.isEmpty)
                .buttonStyle(RoundedButtonStyle(backgroundColor: Color("AccentColor")))
                Spacer()
                if (isSubscribed == false) {
                    VStack {
                        Text("Subscribe to enable live location sending")
                            .padding(.top)
                        Button(action: {
                            appState.subscriptionSheetIsShowing = true
                        }) {
                            Text("Subscribe")
                        }
                        .buttonStyle(RoundedButtonStyle(backgroundColor: Color.white.opacity(0)))
                        .background(LinearGradient(gradient: Gradient(colors: [Color("GradientColor"), Color.accentColor]), startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(25)
                    }
                    .padding()
                    .transition(.move(edge: .bottom))
                }
            }
            .navigationTitle("Send Location")
            
        }
    }
}

struct NewChatView_Previews: PreviewProvider {
    
    static var previews: some View {
        return Group {
            PreviewWrapper(isSubscriber: true)
            PreviewWrapper(isSubscriber: false)
            PreviewWrapper(isSubscriber: false)
                .preferredColorScheme(.dark)
        }
    }
    
    struct PreviewWrapper: View {
        
        @State var recipientEmail: String = ""
        @State var recipientEmailInvalid: Bool = false
        @State var sendLocationInProgress: Bool = false
        @State var isLiveLocation: Bool = false
        @State var selectedLiveLength = 0
        @State var isSubscribed: Bool = false
        
        init(isSubscriber: Bool = false) {
            isSubscribed = isSubscriber
        }
        
        func performMessageSend() {}

        var body: some View {
            
            return NewChatView(
                recipientEmail: $recipientEmail,
                recipientEmailInvalid: $recipientEmailInvalid,
                sendLocationInProgress: $sendLocationInProgress,
                isLiveLocation: $isLiveLocation,
                selectedLiveLength: $selectedLiveLength,
                isSubscribed: $isSubscribed,
                performMessageSend: performMessageSend
            )
        }
    }
    
}
