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
    @Binding var QRCodeFor2FA: String
    
    @State private var invalidCode: Bool = false
    
    let obtain2FAQRCode: () -> Void
    let confirm2FA: () -> Void
    
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
                Image(uiImage: generateQRCode(from: QRCodeFor2FA))
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                Spacer()
            }
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
//                    if (self.loginInProgress) {
//                        ActivityIndicator(isAnimating: true)
//                    }
                    Text("Activate")
                }
            }
            .disabled(invalidCode)
            .buttonStyle(RoundedButtonStyle(backgroundColor: Color("AccentColor")))
        }.padding()
    }
}

struct Activate2FAModal_Previews: PreviewProvider {
    
    static var previews: some View {
        return Group {
            PreviewWrapper()
        }
    }
    
    struct PreviewWrapper: View {
        
        @State var confirm2FACode = ""
        @State var QRCodeFor2FA = ""
        func obtain2FAQRCode() {
            return
        }
        func confirm2FA() {
            return
        }

        var body: some View {
            
            return Activate2FAModal(
                confirm2FACode: $confirm2FACode,
                QRCodeFor2FA: $QRCodeFor2FA,
                obtain2FAQRCode: obtain2FAQRCode,
                confirm2FA: confirm2FA
            )
        }
    }
    
}
