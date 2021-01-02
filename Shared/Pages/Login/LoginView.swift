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
    @Binding var twoFactorModalVisible: Bool
    @Binding var loginInProgress: Bool
    @Binding var serverAddress: String
    @Binding var twoFactorCode: String
    
    @State private var invalidUsername: Bool = false
    @State private var invalidPassword: Bool = false
    
    var performLogin: () -> Void
    var submitTwoFactor: (_ twoFactorCode: String) -> Void
    
    var body: some View {
        NavigationView {
            VStack(alignment: .center) {
                Image("Main Icon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(20)
                    .padding()
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
                Spacer()
                Button(action: self.performLogin) {
                    HStack {
                        if (self.loginInProgress) {
                            ActivityIndicator(isAnimating: true)
                        }
                        Text("Login")
                    }
                }
                .disabled(invalidUsername || invalidPassword || loginInProgress)
                .buttonStyle(RoundedButtonStyle(backgroundColor: Color("AccentColor")))
                Text("").hidden().sheet(
                isPresented: $twoFactorModalVisible) {
                    TwoFactorModal(
                        twoFactorCode: $twoFactorCode,
                        loginInProgress: $loginInProgress,
                        submitTwoFactor: submitTwoFactor
                    )
                }
                Text("").hidden().sheet(
                isPresented: $customServerModalVisible) {
                    CustomServerModal(serverAddress: $serverAddress)
                }
            }
            .padding()
            .navigationBarTitle("Log In")
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Text(""),
                trailing: Button(action: {self.customServerModalVisible.toggle()}) {
                    Image(systemName: "gear").imageScale(.large).foregroundColor(Color("AccentColor"))
            })
        }
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
        @State(initialValue: "https://www.reallyreallyreallylongserveraddress.com") var serverAddress: String
        @State(initialValue: false) var twoFactorModalVisible: Bool
        @State(initialValue: "") var twoFactorCode: String
        
        func login () -> Void {
            return
        }
        
        func submitTwoFactor(_ twoFactorCode: String) -> Void {
            return
        }

          var body: some View {
            LoginView(
                username: $username,
                password: $password,
                customServerModalVisible: $customServerModalVisible,
                twoFactorModalVisible: $twoFactorModalVisible,
                loginInProgress: $loginInProgress,
                serverAddress: $serverAddress,
                twoFactorCode: $twoFactorCode,
                performLogin: login,
                submitTwoFactor: submitTwoFactor
            )
          }
    }
}
