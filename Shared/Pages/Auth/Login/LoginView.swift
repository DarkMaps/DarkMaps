//
//  LoginView.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 06/12/2020.
//

import SwiftUI

struct LoginView: View {
    
    @Binding var username: String
    @Binding var password: String
    @Binding var customServerModalVisible: Bool
    @Binding var loginInProgress: Bool
    @Binding var resetPasswordAlertShowing: Bool
    
    @State private var invalidUsername: Bool = false
    @State private var invalidPassword: Bool = false
    
    var performLogin: () -> Void
    
    var body: some View {
        VStack(alignment: .center) {
            TextFieldWithTitleAndValidation(
                title: "Username",
                invalidText: "Invalid username",
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
                onCommit: self.performLogin
            )
            Button(action: self.performLogin) {
                HStack {
                    if (self.loginInProgress) {
                        ActivityIndicator(isAnimating: true)
                    }
                    Text("Login")
                }
            }
            .disabled(invalidUsername || invalidPassword || loginInProgress || username.isEmpty || password.isEmpty)
            .buttonStyle(RoundedButtonStyle(backgroundColor: Color("AccentColor")))
            Button(action: {self.resetPasswordAlertShowing.toggle()}) { Text("Reset Password")
            }
            .disabled(loginInProgress)
            .padding(.bottom)
            Spacer()
        }.padding()
        .navigationBarTitle("Log In")
        .navigationBarItems(
            leading: Text(""),
            trailing: Button(action: {self.customServerModalVisible.toggle()}) {
                Image(systemName: "gear").imageScale(.large).foregroundColor(Color("AccentColor"))
        })
    }
}

struct LoginView_Previews: PreviewProvider {
    
    static var previews: some View {
        Group {
            PreviewWrapper()
        }
        
    }
    
    struct PreviewWrapper: View {
        @State(initialValue: "matrixMapsTest") var username: String
        @State(initialValue: "") var password: String
        @State(initialValue: false) var customServerModalVisible: Bool
        @State(initialValue: false) var loginInProgress: Bool
        @State(initialValue: false) var resetPasswordAlertShowing: Bool
        
        func login () -> Void {
            return
        }

          var body: some View {
            LoginView(
                username: $username,
                password: $password,
                customServerModalVisible: $customServerModalVisible,
                loginInProgress: $loginInProgress,
                resetPasswordAlertShowing: $resetPasswordAlertShowing,
                performLogin: login
            )
          }
    }
}
