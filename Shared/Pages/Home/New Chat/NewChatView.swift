//
//  NewChatView.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 08/12/2020.
//

import SwiftUI

struct NewChatView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var recipientEmail: String
    @Binding var recipientEmailInvalid: Bool
    @Binding var sendLocationInProgress: Bool
    @Binding var isLiveLocation: Bool
    @Binding var selectedLiveLength: Int
    @Binding var loggedInUser: LoggedInUser?
    @Binding var subscribeInProgress: Bool
    
    var liveLengths = ["15 Minutes", "1 Hour", "4 Hours"]
    
    var performMessageSend: () -> Void
    var getSubscriptionOptions: () -> Void
    
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
                    .disabled(loggedInUser?.subscriptionExpiryDate == nil)
                Picker(
                    selection: $selectedLiveLength,
                    label: Text("Broadcast Length")) {
                    ForEach(0 ..< liveLengths.count) {
                       Text(self.liveLengths[$0])
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .disabled((loggedInUser?.subscriptionExpiryDate == nil) || !isLiveLocation)
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
                Spacer()
                if (loggedInUser?.subscriptionExpiryDate == nil) {
                    VStack {
                        Text("Subscribe to enable live location sending")
                            .padding(.top)
                        Button(action: getSubscriptionOptions) {
                            HStack {
                                if (self.subscribeInProgress) {
                                    ActivityIndicator(isAnimating: true)
                                }
                                Text("Subscribe")
                            }
                        }
                        .disabled(subscribeInProgress)
                        .buttonStyle(RoundedButtonStyle(backgroundColor: Color("AccentColor")))
                    }
                    .background(colorScheme == .dark ?
                                    LinearGradient(gradient: Gradient(colors: [Color.black, Color.accentColor.opacity(0.7)]), startPoint: .top, endPoint: .bottom) :
                                    LinearGradient(gradient: Gradient(colors: [Color.white, Color.accentColor.opacity(0.7)]), startPoint: .top, endPoint: .bottom))
                }
            }.navigationTitle("Send Location")
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
        @State var loggedInUser: LoggedInUser? = nil
        @State var subscribeInProgress: Bool = false
        
        init(isSubscriber: Bool = false) {
            let loggedInUser = LoggedInUser(
                userName: "test@test.com",
                deviceId: 1,
                serverAddress: "test.com",
                authCode: "testAuthCode",
                is2FAUser: true,
                subscriptionExpiryDate: isSubscriber ? Date() : nil)
            _loggedInUser = State(initialValue: loggedInUser)
        }
        
        func performMessageSend() {}
        func getSubscriptionOptions() {}

        var body: some View {
            
            return NewChatView(
                recipientEmail: $recipientEmail,
                recipientEmailInvalid: $recipientEmailInvalid,
                sendLocationInProgress: $sendLocationInProgress,
                isLiveLocation: $isLiveLocation,
                selectedLiveLength: $selectedLiveLength,
                loggedInUser: $loggedInUser,
                subscribeInProgress: $subscribeInProgress,
                performMessageSend: performMessageSend,
                getSubscriptionOptions: getSubscriptionOptions
            )
        }
    }
    
}
