//
//  LoginView.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 06/12/2020.
//

import SwiftUI

struct LoginView: View {
    
//    // This is required to allow modal to be displayed multiple times
//    // See: https://stackoverflow.com/questions/58512344/swiftui-navigation-bar-button-not-clickable-after-sheet-has-been-presented
//    @Environment(\.presentationMode) var presentation
    
    @Binding var username: String
    @Binding var password: String
    @Binding var customServerModalVisible: Bool
    @Binding var loginInProgress: Bool
    @Binding var serverAddress: String
    
    @State private var invalidUsername: Bool = false
    @State private var invalidPassword: Bool = false
    
    var performLogin: () -> Void
    
    var loginParsedServerAddress: String {
        return serverAddress.components(separatedBy: "://").last ?? "** Unknown Address **"
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            TextFieldWithTitleAndValidation(
                title: "Username",
                invalidText: "Invalid username",
                validRegex: "[a-zA-Z0-9]*",
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
            if self.username.count > 0 {
                Group {
                    Text("Logging in as:").foregroundColor(Color(.gray))
                    Text("@\(self.username):\(self.loginParsedServerAddress)").foregroundColor(Color(.gray))
                }
                .transition(.move(edge: .leading))
                .animation(.easeInOut(duration: 0.2))
            }
            Button(action: self.performLogin) {
                HStack {
                    if (self.loginInProgress) {
                        ActivityIndicator(isAnimating: true)
                    }
                    Text("Login")
                }
            }
            .disabled(invalidUsername || invalidPassword || loginInProgress)
            .buttonStyle(RoundedButtonStyle(backgroundColor: Color("Primary")))
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
                Image(systemName: "gear").imageScale(.large).foregroundColor(Color("Primary"))
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
        @State(initialValue: "https://www.reallyreallyreallylongserveraddress.com") var serverAddress: String
        
        func login () -> Void {
            return
        }

          var body: some View {
            LoginView(
                username: $username,
                password: $password,
                customServerModalVisible: $customServerModalVisible,
                loginInProgress: $loginInProgress,
                serverAddress: $serverAddress,
                performLogin: login
            )
          }
    }
}
