//
//  NewChatView.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 08/12/2020.
//

import SwiftUI

struct NewChatView: View {
    
    var body: some View {
        List {
            Text("NewChat")
        }
    }
}

struct NewChatView_Previews: PreviewProvider {
    
    static var previews: some View {
        return Group {
            PreviewWrapper().previewDisplayName("Full Set")
        }
    }
    
    struct PreviewWrapper: View {
        
        func sync () {return}

        var body: some View {
            
            return NewChatView(
            )
        }
    }
    
}
