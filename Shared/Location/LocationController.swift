//
//  LocationController.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 28/12/2020.
//

import Foundation
import SwiftLocation
import CoreLocation

/// Contains the logic for storing location and starting / stopping background location tracking
public class LocationController: ObservableObject {
    
    private var subscription: String?
    @Published var subscriptionOutput: GPSLocationRequest.ProducedData?
    
    public func startLocationUpdates() {
        print("Starting GPS Subscription")
        subscription = SwiftLocation.gpsLocationWith {
            $0.subscription = .continous // continous updated until you stop it
            $0.accuracy = .house
            $0.minTimeInterval = 30
        }.then { result in // you can attach one or more subscriptions via `then`.
            switch result {
            case .success(let newData):
                print("New location: \(newData)")
                self.subscriptionOutput = newData
            case .failure(let error):
                print("An error has occurred: \(error.localizedDescription)")
            }
        }
    }
    
    public func stopLocationUpdates() {
        print("Cancelling GPS Subscription")
        if let subscription = self.subscription {
            SwiftLocation.cancel(subscription: subscription)
        }
    }

    public func getCurrentLocation(completionHandler: @escaping (_: Result<Location, LocationControllerError>) -> ()) {
        SwiftLocation.gpsLocation().then {
            guard let extractedLocation = $0.location else {
                completionHandler(.failure(.unableToRetrieveLocation))
                return
            }
            let newLocation = Location(
                latitude: Float(extractedLocation.coordinate.latitude),
                longitude: Float(extractedLocation.coordinate.longitude))
            completionHandler(.success(newLocation))
        }
    }

}

public enum LocationControllerError: LocalizedError {
    case unableToRetrieveLocation
}
