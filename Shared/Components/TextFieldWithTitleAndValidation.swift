//
//  TextFieldWithTitleAndValidation.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 06/12/2020.
//

import Foundation
import SwiftUI

struct TextFieldWithTitleAndValidation: View {
    
    var title: String
    var invalidText: String
    var validRegex: String = ".*"
    var secureField: Bool = false
    var disableAutocorrection: Bool = false
    
    @Binding var text: String
    @Binding var showInvalidText: Bool
    
    var onCommit: () -> Void = {return}
    
    /// validateText
    /// Validates text in the TextField depending on whether the field is still being edited
    /// Text is assumed to be valid until editing has finished
    /// - Parameter editing: Whether editing is still in progress
    /// - Returns: A Bool defining whther text is valid
    private func validateText(editing: Bool) -> Void {
        if (!editing) {
            let predicate = NSPredicate(format:"SELF MATCHES %@", validRegex)
            showInvalidText = !predicate.evaluate(with: text)
        } else {
            showInvalidText = false
        }
    }
    
    var body: some View {
        VStack {
            VStack {
                Text(title)
                if !secureField {
                    TextField(
                        title,
                        text: $text,
                        onEditingChanged: validateText,
                        onCommit: onCommit)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(disableAutocorrection)
                        .padding(.bottom, -8)
                } else {
                    SecureField(
                        title,
                        text: $text)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .padding(.bottom, -8)
                }
                
            }
            ZStack {
                // A blank Text is retained when no error is show to prevent vertical movement on insertion
                // of the error text
                Text("")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 3)
                if (showInvalidText && text.count > 0) {
                    Text(invalidText)
                        .foregroundColor(.white)
                        .padding(.vertical, 3)
                        .frame(maxWidth: .infinity)
                        .background(Color("AccentColor"))
                        .cornerRadius(3.0)
                        .transition(.move(edge: .leading))
                        .animation(.easeInOut(duration: 0.2))
                }
            }
        }
    }
    
}

struct TextFieldWithTitleAndValidation_Previews: PreviewProvider {
    
    static var previews: some View {
        PreviewWrapper()
    }
    
    struct PreviewWrapper: View {
        var title: String = "Username"
        var invalidText: String = "This is invalid"
        var validRegex: String = "^[A-Za-z0-9]*$"
        @State var text: String = ""
        @State var showInvalidText: Bool = false
        
        func startChat () {}

        var body: some View {
            
            return TextFieldWithTitleAndValidation(
                title: title,
                invalidText: invalidText,
                validRegex: validRegex,
                text: $text,
                showInvalidText: $showInvalidText
            )
        }
    }
    
}
