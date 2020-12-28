//
//  DetailView.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 08/12/2020.
//

import SwiftUI
import MapKit

struct DetailView: View {
    
    @Binding var messageDetails: LocationMessage?
    @Binding var fetchingMessageDetails: Bool
    @Binding var centerCoordinate: CLLocationCoordinate2D?
    @Binding var annotations: [MKPointAnnotation]
    
    let dateFormatter = DateFormatter()
    
    var body: some View {
        
        dateFormatter.timeStyle = .short
        dateFormatter.dateStyle = .short
        
        return ZStack {
            if fetchingMessageDetails {
                Text("Loading data")
            } else if messageDetails == nil {
                Text("Error loading data")
            } else if (centerCoordinate == nil) {
                Text("No location data in message")
            } else {
                VStack(alignment: .leading) {
                    Text(messageDetails!.sender.name).padding(.leading)
                    Text("Last Seen: \(dateFormatter.string(from: Date(ticks: UInt64(messageDetails!.lastReceived))))").padding(.leading)
                    MapView(
                        centerCoordinate: Binding($centerCoordinate)!,
                        annotations: annotations
                    )
                }
                
            }
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
            location: Location(latitude: 53.800755, longitude: -1.549077),
            lastReceived: Int(Date().ticks)
        )
        @State var fetchingMessageDetails = false
        @State var centerCoordinate: CLLocationCoordinate2D? = nil
        @State var annotations: [MKPointAnnotation] = []

        var body: some View {
            return DetailView(
                messageDetails: $messageDetails,
                fetchingMessageDetails: $fetchingMessageDetails,
                centerCoordinate: $centerCoordinate,
                annotations: $annotations
            ).onAppear() {
                self.centerCoordinate = self.messageDetails!.toLocationCoordinate
                let annotation = self.messageDetails!.toAnnotation!
                annotations.append(annotation)
            }
        }
    }
    
}
