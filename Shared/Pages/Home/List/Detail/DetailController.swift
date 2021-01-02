//
//  DetailController.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 08/12/2020.
//
import SwiftUI
import Foundation
import MapKit

struct DetailController: View {
    
    @EnvironmentObject var appState: AppState
    
    @State var fetchingMessageDetails: Bool = true
    @State var messageDetails: LocationMessage? = nil
    @State var centerCoordinate: CLLocationCoordinate2D? = nil
    @State var annotations: [MKPointAnnotation] = []
    
    var sender: ProtocolAddress
    
    var body: some View {
        DetailView(
            messageDetails: $messageDetails,
            fetchingMessageDetails: $fetchingMessageDetails,
            centerCoordinate: $centerCoordinate,
            annotations: $annotations
        ).onAppear() {
            
            guard let loggedInUser = appState.loggedInUser else {
                fetchingMessageDetails = false
                return
            }
            guard let localUserAddress = try? ProtocolAddress(
                    name: loggedInUser.userName,
                    deviceId: UInt32(loggedInUser.deviceId)) else {
                fetchingMessageDetails = false
                return
            }
            
            let messagingStore = MessagingStore(localAddress: localUserAddress)
            
            do {
                let messageDetails = try messagingStore.loadMessage(sender: sender)
                self.messageDetails = messageDetails
                guard let location = messageDetails.location else {
                    fetchingMessageDetails = false
                    return
                }
                self.centerCoordinate = location.toLocationCoordinate
                if let annotation = messageDetails.toAnnotation {
                    self.annotations.append(annotation)
                }
                fetchingMessageDetails = false
            } catch {
                fetchingMessageDetails = false
            }
            
        }
    }
}
