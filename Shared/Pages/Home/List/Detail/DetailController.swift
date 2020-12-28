//
//  DetailController.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 08/12/2020.
//
import SwiftUI
import Foundation

struct DetailController: View {
    
    @EnvironmentObject var appState: AppState
    
    @State var fetchingMessageDetails: Bool = true
    @State var messageDetails: LocationMessage? = nil
    
    var sender: ProtocolAddress
    
    var body: some View {
        DetailView(
            messageDetails: $messageDetails,
            fetchingMessageDetails: $fetchingMessageDetails
        ).onAppear() {
            guard let loggedInUser = appState.loggedInUser else {
                fetchingMessageDetails = false
                return
            }
            guard let localUserAddress = try? ProtocolAddress(
                    name: loggedInUser.userName,
                    deviceId: UInt32(loggedInUser.deviceId ?? 1)) else {
                fetchingMessageDetails = false
                return
            }
            let messagingStore = MessagingStore(localAddress: localUserAddress)
            do {
                let messageDetails = try messagingStore.loadMessage(sender: sender)
                self.messageDetails = messageDetails
                fetchingMessageDetails = false
            } catch {
                fetchingMessageDetails = false
            }
        }
    }
}
