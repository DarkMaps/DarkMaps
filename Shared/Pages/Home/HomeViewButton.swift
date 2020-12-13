//
//  HomeViewButton.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 13/12/2020.
//

import SwiftUI

struct HomeViewButton: View {
    
    var title: String
    var imageName: String
    var onTap: () -> Void
    
    var body: some View {
        GeometryReader { geo in
            VStack(
                alignment: .center,
                spacing: nil) {
                Image(systemName: imageName)
                    .resizable()
                    .scaledToFit()
                Spacer()
                Text(title).padding(.bottom, 2)
            }
            .frame(width: geo.size.width)
            .onTapGesture(perform: {
                onTap()
            })
        }
    }
}
