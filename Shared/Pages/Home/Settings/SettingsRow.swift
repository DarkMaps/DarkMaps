//
//  SettingsRow.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 19/12/2020.
//

import SwiftUI

struct SettingsRow: View {
    
    @Binding var actionInProgress: ActionInProgress?
    var title: String
    var actionDefiningActivityMarker: ActionInProgress
    
    var onTap: () -> Void
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            if actionInProgress == actionDefiningActivityMarker {
                ActivityIndicator(isAnimating: true)
            }
        }
        .onTapGesture(perform: onTap)
        .disabled(actionInProgress != nil)
    }
}
