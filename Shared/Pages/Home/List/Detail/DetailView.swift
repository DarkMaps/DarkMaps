//
//  DetailView.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 08/12/2020.
//

import SwiftUI

struct DetailView: View {
    
    var body: some View {
        VStack {
//            if (chatArray.count > 0) {
//                List(chatArray, id: \.self) { chat in
//                    ChatRow(chatItem: chat, refreshing: self.$refreshing)
//                }
//            } else {
//                NoSharedLocationsView(newChatModalVisible: $newChatModalVisible)
//            }
        }
    }
}

struct DetailView_Previews: PreviewProvider {
    
    static var previews: some View {
        return Group {
            PreviewWrapper().previewDisplayName("Full Set")
        }
    }
    
    struct PreviewWrapper: View {
        
        func sync () {return}

        var body: some View {
            
            return DetailView(
            )
        }
    }
    
}
