//
//  DetailView.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 08/12/2020.
//

import SwiftUI
import MapKit

struct DetailView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var messageDetails: LocationMessage?
    @Binding var fetchingMessageDetails: Bool
    @Binding var centerCoordinate: CLLocationCoordinate2D?
    @Binding var annotations: [MKPointAnnotation]
    
    var body: some View {
        
        return ZStack {
            if fetchingMessageDetails {
                Text("Loading data")
            } else if messageDetails == nil {
                Text("Error loading data")
            } else if (messageDetails!.error != nil) {
                VStack {
                    Spacer()
                    Text("Uh Oh!").font(.largeTitle)
                    Image(systemName: "xmark.octagon.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: UIScreen.main.bounds.size.width * 0.4)
                        .foregroundColor(.red)
                        .padding(.bottom)
                    Spacer()
                    Text("An Error Occured").font(.title)
                    Text(messageDetails!.error!.localizedDescription)
                    Spacer()
                }
            } else if (centerCoordinate == nil) {
                VStack {
                    Spacer()
                    Text("Uh Oh!").font(.largeTitle)
                    Image(systemName: "xmark.octagon.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: UIScreen.main.bounds.size.width * 0.4)
                        .foregroundColor(.red)
                        .padding(.bottom)
                    Spacer()
                    Text("An Error Occured").font(.title)
                    Text("There is no location stored in this message")
                    Spacer()
                }
            } else {
                ZStack {
                    MapView(
                        centerCoordinate: Binding($centerCoordinate)!,
                        annotations: annotations
                    )
                    VStack(alignment: .leading) {
                        VStack(alignment: .leading) {
                            Text(messageDetails!.sender.name)
                                .font(.title3)
                                .padding(.leading)
                                .padding(.top)
                                .padding(.trailing, 40)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            Text("Last Seen: \(messageDetails!.location!.relativeDate)")
                                .italic()
                                .padding(.leading)
                                .padding(.bottom, 30)
                        }
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 200, alignment: .topLeading)
                        .background(
                            LinearGradient(
                                gradient: colorScheme == .dark ?
                                    Gradient(colors: [Color.black, Color.black.opacity(0)]) :
                                    Gradient(colors: [Color.white, Color.white.opacity(0)]),
                                startPoint: .top,
                                endPoint: .bottom))
                        
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)

                }
                
                
            }
        }.navigationBarTitle(Text("Detail"), displayMode: .inline)
        
    }
}

struct DetailView_Previews: PreviewProvider {
    
    static var previews: some View {
        return Group {
            PreviewWrapper(email: "test@test.com").previewDisplayName("Full Set")
            PreviewWrapper(email: "reallyreallyreallylongtest@test.com").previewDisplayName("Long Email")
            PreviewWrapper(email: "reallyreallyreallylongtest@test.com").preferredColorScheme(.dark).previewDisplayName("Long Email")
            PreviewWrapper(
                email:"reallyreallyreallylongtest@test.com",
                isError: true)
                .preferredColorScheme(.dark)
                .previewDisplayName("With Error")
        }
    }
    
    struct PreviewWrapper: View {
        
        @State var messageDetails: LocationMessage?
        @State var fetchingMessageDetails = false
        @State var centerCoordinate: CLLocationCoordinate2D? = nil
        @State var annotations: [MKPointAnnotation] = []
        
        init(email: String, isError: Bool = false) {
            _messageDetails = State(initialValue: LocationMessage(
                id: 3,
                sender: try! ProtocolAddress(
                    name: email,
                    deviceId: UInt32(324)
                ),
                location: isError ? nil : Location(latitude: 53.800755, longitude: -1.549077, time: Date()),
                error: isError ? .serverError : nil
            ))
        }

        var body: some View {
            return DetailView(
                messageDetails: $messageDetails,
                fetchingMessageDetails: $fetchingMessageDetails,
                centerCoordinate: $centerCoordinate,
                annotations: $annotations
            ).onAppear() {
                if let location = self.messageDetails!.location {
                    self.centerCoordinate =  location.toLocationCoordinate
                    let annotation = self.messageDetails!.toAnnotation!
                    annotations.append(annotation)
                }
            }
        }
    }
    
}
