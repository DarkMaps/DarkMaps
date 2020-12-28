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
public class LocationController {

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
