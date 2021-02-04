//
//  Entry.swift
//  DarkMaps
//
//  Created by Matthew Roche on 29/01/2021.
//

import SwiftUI

struct Entry: View {
    
    @State var isLoginLinkActive = false
    @State var isRegisterLinkActive = false
    @State var customAuthServer = "https://api.dark-maps.com"
    
    var body: some View {
        NavigationView {
            VStack {
                Image("hero")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: UIScreen.main.bounds.size.width * 1.2)
                    .cornerRadius(20)
                    .padding(.leading, 30)
                Text("Encrypted Location Sharing").font(.title)
                Text("Dark Maps").font(.title2)
                Spacer()
                Text("Login or Sign Up")
                    .padding()
                Button(action: {isLoginLinkActive = true}, label: {
                    Text("Login")
                })
                .buttonStyle(RoundedButtonStyle(backgroundColor: Color("AccentColor")))
                Button(action: {isRegisterLinkActive = true}, label: {
                    Text("Sign Up")
                })
                .buttonStyle(RoundedButtonStyle(backgroundColor: Color("AccentColor")))
                NavigationLink(destination: LoginController(customAuthServer: $customAuthServer), isActive: $isLoginLinkActive) { EmptyView() }.hidden()
                NavigationLink(destination: RegisterController(customAuthServer: $customAuthServer), isActive: $isRegisterLinkActive) { EmptyView() }.hidden()
            }.navigationBarHidden(true)
        }
    }
}

struct Entry_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Entry()
            Entry()
                .preferredColorScheme(.dark)
            Entry()
                .previewLayout(.device)
                .previewDevice("iPod touch (7th generation)")
        }
    }
}
