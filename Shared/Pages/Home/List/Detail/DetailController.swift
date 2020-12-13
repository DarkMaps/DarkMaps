//
//  DetailController.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 08/12/2020.
//
import SwiftUI

struct DetailController: View {
    
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            HomeView(
            )
        }
        
    }
}
