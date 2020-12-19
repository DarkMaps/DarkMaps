//
//  Deactivate2FAModal.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 15/12/2020.
//

import SwiftUI

struct Deactivate2FAModal: View {
    
    @Binding var deactivate2FACode: String
    @Binding var actionInProgress: ActionInProgress?
    @State var invalidCode: Bool = false
    let deactivate2FA: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Deactivate 2FA").font(.largeTitle)
            Spacer()
            TextFieldWithTitleAndValidation(
                title: "Enter the code from your programme",
                invalidText: "Invalid code",
                validRegex: ".{4,}",
                text: $deactivate2FACode,
                showInvalidText: $invalidCode
            )
            Button(action: self.deactivate2FA) {
                HStack {
                    if (actionInProgress == .deactivate2FA) {
                        ActivityIndicator(isAnimating: true)
                    }
                    Text("Deactivate")
                }
            }
            .disabled(invalidCode)
            .buttonStyle(RoundedButtonStyle(backgroundColor: Color("AccentColor")))
            Spacer()
        }.padding()
    }
}

struct Deactivate2FAModal_Previews: PreviewProvider {
    
    static var previews: some View {
        return Group {
            PreviewWrapper()
        }
    }
    
    struct PreviewWrapper: View {
        
        @State var deactivate2FACode = ""
        @State var actionInProgress: ActionInProgress? = nil
        func deactivate2FA() {
            return
        }

        var body: some View {
            
            return Deactivate2FAModal(
                deactivate2FACode: $deactivate2FACode,
                actionInProgress: $actionInProgress,
                deactivate2FA: deactivate2FA
            )
        }
    }
    
}
