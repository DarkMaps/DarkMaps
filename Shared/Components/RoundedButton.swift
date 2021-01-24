//
//  RoundedButton.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 06/12/2020.
//

import Foundation
import SwiftUI

struct RoundedButtonStyle: ButtonStyle {
    
    var backgroundColor: Color
    var padded: Bool
    
    init(backgroundColor: Color, padded: Bool = true) {
        self.backgroundColor = backgroundColor
        self.padded = padded
    }
    
    func makeBody(configuration: ButtonStyle.Configuration) -> some View {
        RoundedButton(configuration: configuration, backgroundColor: backgroundColor, padded: padded)
    }

    struct RoundedButton: View {
        let configuration: ButtonStyle.Configuration
        let backgroundColor: Color
        let padded: Bool
        @Environment(\.isEnabled) private var isEnabled: Bool
        var body: some View {
            configuration.label
                .foregroundColor(Color.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical)
                .background(backgroundColor)
                .cornerRadius(25)
                .opacity(isEnabled ? 1 : 0.5)
                .padding(.horizontal)
                .padding(.vertical, padded ? 3 : 0)
        }
    }
}

struct RoundedButton_Previews: PreviewProvider {
    
    static var previews: some View {
        
        return Group {
            PreviewWrapper(backgroundColor: Color.green)
                .previewLayout(.fixed(width: 350, height: 120))
            PreviewWrapper(backgroundColor: Color.red)
                .previewLayout(.fixed(width: 350, height: 120))
            PreviewWrapper(backgroundColor: Color.blue)
                .previewLayout(.fixed(width: 350, height: 120))
            PreviewWrapper(backgroundColor: Color.blue, disabled: true)
            .previewLayout(.fixed(width: 350, height: 120))
        }
    }
    
    struct PreviewWrapper: View {
        
        var backgroundColor: Color
        var disabled = false

        var body: some View {
            
            return Button("Text") { return }
                .buttonStyle(RoundedButtonStyle(backgroundColor: backgroundColor))
            .disabled(disabled)
        }
    }
    
}
