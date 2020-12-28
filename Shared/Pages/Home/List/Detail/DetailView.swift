//
//  DetailView.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 08/12/2020.
//

import SwiftUI

struct DetailView: View {
    
    @Binding var messageDetails: LocationMessage?
    @Binding var fetchingMessageDetails: Bool
    
    var body: some View {
        ZStack {
            if fetchingMessageDetails {
                Text("Loading data")
            } else if messageDetails == nil {
                Text("Error loading data")
            } else if (messageDetails!.location == nil) {
                Text("No location data in message")
            } else {
                VStack {
                    Text("Location:")
                    Text("Latitude: \(messageDetails!.location!.latitude)")
                    Text("Longitude: \(messageDetails!.location!.longitude)")
                }
                
            }
            Text("").hidden().navigationTitle("Detail")
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
        
        @State var messageDetails: LocationMessage? = LocationMessage(
            id: 3,
            sender: try! ProtocolAddress(
                name: "test@test.com",
                deviceId: UInt32(324)
            ),
            location: Location(latitude: 2.345346, longitude: 5.2323535),
            lastReceived: Int(Date().ticks)
        )
        @State var fetchingMessageDetails = false

        var body: some View {
            return DetailView(
                messageDetails: $messageDetails,
                fetchingMessageDetails: $fetchingMessageDetails
            )
        }
    }
    
}
