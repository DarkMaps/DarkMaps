//
//  TextFieldAlert.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 19/12/2020.
//

import SwiftUI

struct TextFieldAlert<Presenting>: View where Presenting: View {

    @Binding var isShowing: Bool
    @Binding var text: String
    let presenting: Presenting
    let title: String
    let textBoxPlaceholder: String?
    let secureField: Bool
    let onDismiss: () -> Void

    var body: some View {
        GeometryReader { (deviceSize: GeometryProxy) in
            ZStack {
                self.presenting
                    .disabled(isShowing)
                VStack(alignment: .center) {
                    Spacer()
                    VStack {
                        VStack {
                            Text(self.title)
                            if (secureField) {
                                SecureField(self.title, text: self.$text)
                                    .id(self.isShowing)
                            } else {
                                TextField(self.textBoxPlaceholder ?? self.title, text: self.$text)
                                    .id(self.isShowing)
                            }
                            Divider().padding(.vertical)
                            HStack {
                                Button(action: {
                                    withAnimation {
                                        self.isShowing.toggle()
                                    }
                                }) {
                                    Text("Cancel")
                                }
                                Button(action: {
                                    withAnimation {
                                        onDismiss()
                                        self.isShowing.toggle()
                                    }
                                }) {
                                    Text("OK")
                                }
                            }
                        }.padding()
                    }
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 1)
                    .padding()
                    Spacer()
                }
                .background(Color(UIColor.gray.withAlphaComponent(0.7)))
                .frame(
                    width: deviceSize.size.width,
                    height: deviceSize.size.height
                )
                .opacity(self.isShowing ? 1 : 0)
            }
        }
    }
}

extension View {

    func textFieldAlert(isShowing: Binding<Bool>,
                        text: Binding<String>,
                        title: String,
                        textBoxPlaceholder: String? = nil,
                        secureField: Bool = false,
                        onDismiss: @escaping () -> Void) -> some View {
        TextFieldAlert(isShowing: isShowing,
                       text: text,
                       presenting: self,
                       title: title,
                       textBoxPlaceholder: textBoxPlaceholder,
                       secureField: secureField,
                       onDismiss: onDismiss)
    }

}
