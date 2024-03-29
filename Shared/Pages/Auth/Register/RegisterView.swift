//
//  RegisterView.swift
//  DarkMaps (iOS)
//
//  Created by Matthew Roche on 05/01/2021.
//

import SwiftUI

struct RegisterView: View {
    
    @Binding var username: String
    @Binding var password: String
    @Binding var registerInProgress: Bool
    @Binding var customServerModalVisible: Bool
    
    @State private var invalidUsername: Bool = false
    @State private var invalidPassword: Bool = false
    
    var performRegister: () -> Void
    
    var body: some View {
        VStack(alignment: .center) {
            TextFieldWithTitleAndValidation(
                title: "Email",
                invalidText: "Invalid email",
                validRegex: "^([a-zA-Z0-9_\\-\\.]+)@([a-zA-Z0-9_\\-\\.]+)\\.([a-zA-Z]{2,5})$",
                disableAutocorrection: true,
                text: $username,
                showInvalidText: $invalidUsername
            )
            TextFieldWithTitleAndValidation(
                title: "Password",
                invalidText: "Invalid password",
                secureField: true,
                text: $password,
                showInvalidText: $invalidPassword,
                onCommit: self.performRegister
            )
            Button(action: self.performRegister) {
                HStack {
                    if (self.registerInProgress) {
                        ActivityIndicator(isAnimating: true)
                            .transition(AnyTransition.opacity.combined(with: .move(edge: .leading)))
                    }
                    Text("Register")
                }
            }
            .disabled(invalidUsername || invalidPassword || registerInProgress || username.isEmpty || password.isEmpty)
            .buttonStyle(RoundedButtonStyle(backgroundColor: Color("AccentColor")))
            .padding(.bottom)
            Spacer()
        }.padding()
        .navigationBarTitle("Register")
        .navigationBarItems(
            leading: Text(""),
            trailing: Button(action: {self.customServerModalVisible.toggle()}) {
                Image(systemName: "gear").imageScale(.large).foregroundColor(Color("AccentColor"))
        })
    }
}

struct RegisterView_Previews: PreviewProvider {
    
    static var previews: some View {
        Group {
            PreviewWrapper()
            PreviewWrapper()
                .previewDevice("iPod touch (7th generation)")
        }
        
    }
    
    struct PreviewWrapper: View {
        @State(initialValue: "matrixMapsTest") var username: String
        @State(initialValue: "") var password: String
        @State(initialValue: false) var registerInProgress: Bool
        @State(initialValue: false) var customServerModalVisible: Bool
        @State(initialValue: false) var loginBoxShowing: Bool
        
        func register () -> Void {
            return
        }

          var body: some View {
            RegisterView(
                username: $username,
                password: $password,
                registerInProgress: $registerInProgress,
                customServerModalVisible: $customServerModalVisible,
                performRegister: register
            )
          }
    }
}
