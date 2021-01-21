//
//  2FAModal.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 06/12/2020.
//

import SwiftUI

struct TwoFactorModal: View {
    
    @Binding var twoFactorCode: String
    @Binding var loginInProgress: Bool
    
    @State var showInvalidTwoFactorCodeText = false
    
    @Environment(\.presentationMode) var presentationMode
    
    var submitTwoFactor: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Two Factor Authentication")
                .font(.title)
            Spacer()
            TextFieldWithTitleAndValidation(
                title: "Two Factor Authentication Code",
                invalidText: "Please enter a valid code",
                validRegex: "0-9",
                text: $twoFactorCode,
                showInvalidText: $showInvalidTwoFactorCodeText,
                onCommit: {submitTwoFactor(twoFactorCode)}
            )
            .padding(.bottom)
            Button(action: {submitTwoFactor(twoFactorCode)}) {
                HStack {
                    if (self.loginInProgress) {
                        ActivityIndicator(isAnimating: true)
                    }
                    Text("Submit")
                }
            }
            .disabled(showInvalidTwoFactorCodeText || twoFactorCode.isEmpty)
            .buttonStyle(RoundedButtonStyle(backgroundColor: Color("AccentColor")))
            Spacer()
        }
        .padding()
    }
}

struct TwoFactorModal_Previews: PreviewProvider {
    
    static var previews: some View {
        PreviewWrapper()
    }
    
    struct PreviewWrapper: View {
        @State var twoFactorCode: String = "1234"
        @State var loginInProgress: Bool = false
        func submitTwoFactor(_ twoFactorCode: String) {
            return
        }
        
        var body: some View {
            return TwoFactorModal(
                twoFactorCode: $twoFactorCode,
                loginInProgress: $loginInProgress,
                submitTwoFactor: submitTwoFactor
            )
        }
    }
    
}

