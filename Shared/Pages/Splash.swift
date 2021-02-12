//
//  Splash.swift
//  DarkMaps
//
//  Created by Matthew Roche on 12/02/2021.
//

import SwiftUI

struct Splash: View {
    var body: some View {
        ZStack {
            Color("AccentColor")
            VStack(alignment: .center) {
                HStack(alignment: .center) {
                    Image("Main Icon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .ignoresSafeArea()
                        .frame(width: UIScreen.main.bounds.size.width - 150)
                }
            }
        }.ignoresSafeArea()
    }
}

struct Splash_Previews: PreviewProvider {
    static var previews: some View {
        Splash()
    }
}
