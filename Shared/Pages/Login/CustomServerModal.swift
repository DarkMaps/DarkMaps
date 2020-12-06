//
//  CustomServerModal.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 06/12/2020.
//

import SwiftUI

struct CustomServerModal: View {
    
    @Binding var serverAddress: String
    
    @State var showInvalidServerText = false
    
    @Environment(\.presentationMode) var presentationMode
    
    func dismissModal() {
        presentationMode.wrappedValue.dismiss()
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Use a custom server")
                .font(.title)
            Spacer()
            TextFieldWithTitleAndValidation(
                title: "Server Address",
                invalidText: "Server address is invalid",
                validRegex: "^https?:\\/\\/(www\\.)?[a-z0-9]*?\\.?[a-z0-9]*\\.[a-z]{2,3}(\\.[a-z]{2,3})?$",
                text: $serverAddress,
                showInvalidText: $showInvalidServerText,
                onCommit: dismissModal
            )
            .padding(.bottom)
            Button("Set", action: dismissModal)
                .disabled(showInvalidServerText)
                .buttonStyle(RoundedButtonStyle(backgroundColor: Color("AccentColor")))
            Spacer()
        }
        .padding()
    }
}

struct CustomServerModal_Previews: PreviewProvider {
    
    static var previews: some View {
        PreviewWrapper()
    }
    
    struct PreviewWrapper: View {
        @State var serverAddress = "www.testAddress.com"
        var body: some View {
            return CustomServerModal(serverAddress: $serverAddress)
        }
    }
    
}
