//
//  SettingsView.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 08/12/2020.
//

import SwiftUI

struct SettingsView: View {
    
    var logUserOut: () -> Void
    
    var body: some View {
        List {
            Text("Log Out").onTapGesture(perform: logUserOut)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    
    static var previews: some View {
        return Group {
            PreviewWrapper().previewDisplayName("Full Set")
        }
    }
    
    struct PreviewWrapper: View {
        
        func logUserOut () {return}

        var body: some View {
            
            return SettingsView(
                logUserOut: logUserOut
            )
        }
    }
    
}
