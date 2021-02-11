//
//  TextFieldAlert.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 19/12/2020.
//

import SwiftUI

struct TextFieldAlert<Presenting>: View where Presenting: View {
    
    @Environment(\.colorScheme) var colorScheme

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
                            VStack {
                                Text(self.title).padding(.bottom, 10).font(Font.body.bold())
                                if (secureField) {
                                    SecureField(self.title, text: self.$text)
                                        .id(self.isShowing)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .overlay(
                                            Rectangle()
                                                .stroke(Color(UIColor.systemGray3), lineWidth: 1))
                                } else {
                                    TextField(self.textBoxPlaceholder ?? self.title, text: self.$text)
                                        .id(self.isShowing)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .overlay(
                                            Rectangle()
                                                .stroke(Color(UIColor.systemGray3), lineWidth: 1))
                                }
                            }.padding()
                            Rectangle()
                                .foregroundColor(Color(UIColor.systemGray4))
                                .frame(height:1)
                            HStack() {
                                Spacer()
                                Button(action: {
                                    withAnimation {
                                        self.isShowing.toggle()
                                    }
                                }) {
                                    Text("Cancel").font(Font.body.bold())
                                }
                                .padding()
                                Spacer()
                                Button(action: {
                                    withAnimation {
                                        onDismiss()
                                        self.isShowing.toggle()
                                    }
                                }) {
                                    Text("OK").font(Font.body.bold())
                                }
                                .padding()
                                Spacer()
                            }
                        }
                    }
                    .background(colorScheme == .dark ?
                        Color.black :
                                    Color(UIColor.systemGray5))
                    .cornerRadius(10)
                    .padding()
                    Spacer()
                }
                .background(
                    Color(UIColor.black.withAlphaComponent(0.7))
                )
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

struct TextFieldAlert_Previews: PreviewProvider {
    
    static var previews: some View {
        
        return Group {
            PreviewWrapper()
                .previewLayout(.fixed(width: 350, height: 120))
            PreviewWrapper()
                .preferredColorScheme(.dark)
                .previewLayout(.fixed(width: 350, height: 120))
            PreviewWrapper(secureField: true)
                .previewLayout(.fixed(width: 350, height: 120))
            PreviewWrapper(secureField: true)
                .preferredColorScheme(.dark)
                .previewLayout(.fixed(width: 350, height: 120))
        }
    }
    
    struct PreviewWrapper: View {
        
        @State var isShowing = false
        @State var text = ""
        @State var secureField: Bool
        
        init(secureField: Bool = false) {
            _secureField = State(initialValue: secureField)
        }

        var body: some View {
            
            return Button("Click to show alert") { isShowing.toggle() }
                .textFieldAlert(
                    isShowing: $isShowing,
                    text: $text,
                    title: "A title",
                    secureField: secureField,
                    onDismiss: {})
        }
    }
    
}
