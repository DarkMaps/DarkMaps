//
//  Activate2FAModal.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 15/12/2020.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct Activate2FAModal: View {
    
    @Binding var confirm2FACode: String
    @Binding var QRCodeFor2FA: String?
    @Binding var actionInProgress: ActionInProgress?
    
    @State private var invalidCode: Bool = false
    
    @Environment(\.presentationMode) var presentation
    
    let obtain2FAQRCode: () -> Void
    let confirm2FA: () -> Void
    let copyCodeToClipboard: () -> Void
    
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    
    //https://www.hackingwithswift.com/books/ios-swiftui/generating-and-scaling-up-a-qr-code
    func generateQRCode(from string: String) -> UIImage {
        let data = Data(string.utf8)
        filter.setValue(data, forKey: "inputMessage")

        if let outputImage = filter.outputImage {
            if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgimg)
            }
        }

        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Activate 2FA").font(.largeTitle)
            Spacer()
            HStack {
                Spacer()
                if QRCodeFor2FA != nil {
                    Image(uiImage: generateQRCode(from: QRCodeFor2FA!))
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                } else {
                    ActivityIndicator(isAnimating: true)
                        .frame(width: 200, height: 200)
                }
                Spacer()
            }
            Button(action: self.copyCodeToClipboard) {
                    Text("Copy to clipboard")
            }
            .buttonStyle(RoundedButtonStyle(backgroundColor: Color("AccentColor")))
            .disabled(QRCodeFor2FA == nil)
            Spacer()
            TextFieldWithTitleAndValidation(
                title: "Enter the code from your programme",
                invalidText: "Invalid code",
                validRegex: ".{4,}",
                text: $confirm2FACode,
                showInvalidText: $invalidCode
            )
            Button(action: self.confirm2FA) {
                HStack {
                    if (actionInProgress == .confirm2FA) {
                        ActivityIndicator(isAnimating: true)
                    }
                    Text("Activate")
                }
            }
            .disabled(invalidCode)
            .buttonStyle(RoundedButtonStyle(backgroundColor: Color("AccentColor")))
        }
        .padding()
        .onAppear() {
            obtain2FAQRCode()
        }
    }
}

struct Activate2FAModal_Previews: PreviewProvider {
    
    static var previews: some View {
        return Group {
            PreviewWrapper()
            PreviewWrapper(QRCode: "testCode")
        }
    }
    
    struct PreviewWrapper: View {
        
        @State var confirm2FACode = ""
        @State var QRCodeFor2FA: String?
        @State var actionInProgress: ActionInProgress? = nil
        func obtain2FAQRCode() {
            return
        }
        func confirm2FA() {
            return
        }
        func copyCodeToClipboard() {}
        
        init(QRCode: String? = nil) {
            self._QRCodeFor2FA = State(initialValue: QRCode)
        }

        var body: some View {
            
            return Activate2FAModal(
                confirm2FACode: $confirm2FACode,
                QRCodeFor2FA: $QRCodeFor2FA,
                actionInProgress: $actionInProgress,
                obtain2FAQRCode: obtain2FAQRCode,
                confirm2FA: confirm2FA,
                copyCodeToClipboard: copyCodeToClipboard
            )
        }
    }
    
}
