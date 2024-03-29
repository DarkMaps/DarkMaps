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
    
    @Published var subscriptionOutput: GPSLocationRequest.ProducedData?
    
    private var subscription: String?
    private let notificationCentre = NotificationCenter.default
    
    init() {
        notificationCentre.addObserver(self,
                                       selector: #selector(self.handleLiveMessageUpdateNotification(_:)),
                                       name: .messagingStore_LiveMessagesUpdates,
                                       object: nil)
    }
    
    @objc private func handleLiveMessageUpdateNotification(_ notification: NSNotification) {
        guard let count = notification.userInfo?["count"] as? Int else {
            print("No count found in Live Message Update Notification")
            return
        }
        if count == 0 {
            self.stopLocationUpdates()
        } else {
            self.startLocationUpdates()
        }
    }
    
    private func sendNotification(location: GPSLocationRequest.ProducedData) {
        notificationCentre.post(name: .locationController_NewLocationReceived, object: nil, userInfo: ["location": location])
    }
    
    public func startLocationUpdates() {
        print("Starting GPS Subscription")
        subscription = SwiftLocation.gpsLocationWith {
            $0.subscription = .continous // continous updated until you stop it
            $0.accuracy = .room
            $0.minTimeInterval = 30
            $0.activityType = .fitness
            $0.precise = .fullAccuracy
        }.then { result in // you can attach one or more subscriptions via `then`.
            switch result {
            case .success(let newData):
                print("New location: \(newData)")
                self.subscriptionOutput = newData
                self.sendNotification(location: newData)
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
        SwiftLocation.gpsLocation(accuracy: .room, timeout: .delayed(30)).then {
            guard let extractedLocation = $0.location else {
                completionHandler(.failure(.unableToRetrieveLocation))
                return
            }
            let newLocation = Location(
                latitude: extractedLocation.coordinate.latitude,
                longitude: extractedLocation.coordinate.longitude,
                time: Date())
            completionHandler(.success(newLocation))
        }
    }

}

public enum LocationControllerError: LocalizedError {
    case unableToRetrieveLocation
}

extension LocationControllerError {
    
    public var errorDescription: String? {
        switch self {
        case .unableToRetrieveLocation:
            return NSLocalizedString("Unable to access location.", comment: "")
        }
    }
}
