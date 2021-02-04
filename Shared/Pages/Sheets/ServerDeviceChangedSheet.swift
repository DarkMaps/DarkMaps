//
//  ServerDeviceChangedSheet.swift
//  DarkMaps
//
//  Created by Matthew Roche on 21/01/2021.
//

import SwiftUI

struct ServerDeviceChangedSheet: View {
    
    @EnvironmentObject var appState: AppState
    
    @Environment(\.presentationMode) var presentationMode
    
    func handleDismissal() {
        print("Dismiss")
        guard let messagingController = appState.messagingController else {
            appState.loggedInUser = nil
            return
        }
        messagingController.deleteAllLocalData()
        appState.loggedInUser = nil
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
                Text("The device stored on the server no longer matches the details on this device.")
            }
            Spacer()
            ScrollView {
                VStack(alignment: .leading) {
                    Text("Why has this happened?").font(.headline)
                    Text("Another device has logged onto the server with your user name and chosen to erase your device. Current the Dark Maps server only supports one device per email address.")
                    Text("Why do you have this limitation?").font(.headline).padding(.top, 2)
                    Text("Having only one device per user account is a security feature, as it ensures you always know precisely who your data is being sent to.")
                    Text("What happens now?").font(.headline).padding(.top, 2)
                    Text("You will be logged out. If you wish, you can log back in to Dark Maps and choose to erase the device details stored on the server. However, all your current data has been lost.")
                }
            }
            Spacer()
            Button(action: handleDismissal) {
                Text("OK")
            }.buttonStyle(RoundedButtonStyle(backgroundColor: .red))
        }.padding()
        
    }
}

struct ServerDeviceChangedSheet_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ServerDeviceChangedSheet()
            ServerDeviceChangedSheet()
                .previewDevice("iPod touch (7th generation)")
        }
    }
}

