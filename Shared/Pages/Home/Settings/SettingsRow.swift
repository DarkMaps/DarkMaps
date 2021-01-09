//
//  SettingsRow.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 19/12/2020.
//

import SwiftUI

struct SettingsRow: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var actionInProgress: ActionInProgress?
    
    var title: String
    var subtitle: String?
    var iconName: String?
    var actionDefiningActivityMarker: ActionInProgress?
    
    init(actionInProgress: Binding<ActionInProgress?>, title: String, subtitle: String? = nil, iconName: String? = nil, actionDefiningActivityMarker: ActionInProgress?, onTap: @escaping () -> Void = {}) {
        self._actionInProgress = actionInProgress
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.actionDefiningActivityMarker = actionDefiningActivityMarker
        self.onTap = onTap
    }
    
    var onTap: () -> Void
    
    var body: some View {
        HStack {
            ZStack {
                Rectangle()
                    .fill(Color.black.opacity(0))
                    .frame(width: 25)
                if (iconName != nil) {
                    Image(systemName: iconName!)
                }
            }
            VStack(alignment: .leading) {
                Text(title)
                if subtitle != nil {
                    Text(subtitle!)
                }
            }
            Spacer()
            if actionInProgress == actionDefiningActivityMarker && actionDefiningActivityMarker != nil {
                ActivityIndicator(isAnimating: true)
            }
        }
        .onTapGesture(perform: onTap)
        .disabled(actionInProgress != nil)
    }
}
