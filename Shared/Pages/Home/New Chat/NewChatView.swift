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
    @Binding var liveLocationOptionsVisible: Bool
    // This is unfortunately necessary for animation
    @Binding var isSubscribed: Bool
    
    var liveLengths = ["15 Minutes", "1 Hour", "4 Hours"]
    
    var performMessageSend: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                Text("Send Location")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .padding(.top, 10)
                    .padding(.leading)
                Spacer()
            }
            TextFieldWithTitleAndValidation(
                title: "Recipient's Email",
                invalidText: "Invalid email",
                validRegex: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}",
                disableAutocorrection: true,
                text: $recipientEmail,
                showInvalidText: $recipientEmailInvalid
            ).padding(.horizontal).padding(.top)
            if isSubscribed {
                VStack {
                    Toggle("Live Location Active", isOn: $isLiveLocation.animation())
                        .toggleStyle(SwitchToggleStyle(tint: Color("AccentColor")))
                        .padding()
                        .disabled(isSubscribed == false)
                    DarkMapsPicker(
                        selectedLiveLength: $selectedLiveLength,
                        liveLengths: liveLengths,
                        disabled: (isSubscribed == false) || !isLiveLocation)
                        .padding(.vertical)
                }
            }
            Button(action: self.performMessageSend) {
                HStack {
                    if (self.sendLocationInProgress) {
                        ActivityIndicator(isAnimating: true)
                    } else if (self.isLiveLocation) {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.yellow)
                            .transition(AnyTransition.opacity.combined(with: .move(edge: .leading)))
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
                    Rectangle().fill(Color("AccentColor")).frame(maxWidth: .infinity, maxHeight: 4)
                    Text("Subscribe to enable live location sending")
                        .padding(.top, 3)
                    Button(action: {
                        appState.subscriptionSheetIsShowing = true
                    }) {
                        Text("Subscribe")
                    }
                    .buttonStyle(RoundedButtonStyle(backgroundColor: Color("AccentColor")))
                }
                .transition(.move(edge: .bottom))
            }
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
            PreviewWrapper(isSubscriber: true)
                .previewDevice("iPod touch (7th generation)")
                .preferredColorScheme(.dark)
        }
    }
    
    struct PreviewWrapper: View {
        
        @State var recipientEmail: String = ""
        @State var recipientEmailInvalid: Bool = false
        @State var sendLocationInProgress: Bool = false
        @State var isLiveLocation: Bool = false
        @State var selectedLiveLength = 0
        @State var liveLocationOptionsVisible = false
        @State var isSubscribed: Bool
        
        init(isSubscriber: Bool = false) {
            _isSubscribed = State(initialValue: isSubscriber)
        }
        
        func performMessageSend() {}

        var body: some View {
            
            return NewChatView(
                recipientEmail: $recipientEmail,
                recipientEmailInvalid: $recipientEmailInvalid,
                sendLocationInProgress: $sendLocationInProgress,
                isLiveLocation: $isLiveLocation,
                selectedLiveLength: $selectedLiveLength,
                liveLocationOptionsVisible: $liveLocationOptionsVisible,
                isSubscribed: $isSubscribed,
                performMessageSend: performMessageSend
            )
        }
    }
    
}

struct DarkMapsPicker: View {
    
    @Binding var selectedLiveLength: Int
    
    var liveLengths: [String]
    var disabled: Bool
    
    init(selectedLiveLength: Binding<Int>, liveLengths: [String], disabled: Bool) {
        
        _selectedLiveLength = selectedLiveLength
        self.liveLengths = liveLengths
        self.disabled = disabled
        
        //this changes the "thumb" that selects between items
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(Color("AccentColor"))

        //these lines change the text color for various states
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor : UIColor.white], for: .selected)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor : UIColor.white], for: .normal)
    }
    
    var body: some View {
        
        Picker(
            selection: $selectedLiveLength,
            label: Text("Broadcast Length")) {
            ForEach(0 ..< liveLengths.count) {
               Text(self.liveLengths[$0])
            }
        }
        .accentColor(Color("AccentColor"))
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
        .disabled(disabled)
        
    }
    
}
