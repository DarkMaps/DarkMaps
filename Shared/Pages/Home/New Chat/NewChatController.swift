//
//  NewChatController.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 08/12/2020.
//
import SwiftUI

struct NewChatController: View {
    
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            NewChatView(
            )
        }
        
    }
}
