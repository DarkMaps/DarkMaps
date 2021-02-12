//
//  UnauthorisedSheet.swift
//  DarkMaps
//
//  Created by Matthew Roche on 24/01/2021.
//

import SwiftUI

struct UnauthorisedSheet: View {
    
    @EnvironmentObject var appState: AppState
    
    @Environment(\.presentationMode) var presentationMode
    
    func handleDismissal() {
        print("Dismiss")
        guard let messagingController = appState.messagingController else {
            withAnimation {
                appState.loggedInUser = nil
            }
            return
        }
        messagingController.deleteAllLocalData()
        withAnimation {
            appState.loggedInUser = nil
        }
        self.presentationMode.wrappedValue.dismiss()
    }
    
    var body: some View {
        VStack {
            VStack{
                Text("Uh Oh!").font(.largeTitle)
                Image(systemName: "xmark.octagon.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: UIScreen.main.bounds.size.width * 0.4)
                    .foregroundColor(.red)
                    .padding(.bottom)
                Text("You have been logged out by the server.")
            }
            Spacer()
            VStack(alignment: .leading) {
                Text("Why has this happened?").font(.headline)
                Text("The login credentials stored by the app are no longer recognised by the server.")
                Text("What happens now?").font(.headline).padding(.top, 2)
                Text("You will be logged out. If you wish, you can try to log back in to Dark Maps.")
            }
            Spacer()
            Button(action: handleDismissal) {
                Text("OK")
            }.buttonStyle(RoundedButtonStyle(backgroundColor: .red))
        }.padding()
    }
}

struct UnauthorisedSheet_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            UnauthorisedSheet()
            UnauthorisedSheet()
                .previewDevice("iPod touch (7th generation)")
        }
    }
}
