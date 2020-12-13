//
//  ListView.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 08/12/2020.
//

import SwiftUI

struct ListView: View {
    
    var body: some View {
        List {
            Text("List")
        }
    }
}

struct ListView_Previews: PreviewProvider {
    
    static var previews: some View {
        PreviewWrapper().previewDisplayName("Full Set")
    }
    
    struct PreviewWrapper: View {

        var body: some View {
            return ListView()
        }
    }
    
}

