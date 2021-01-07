//
//  MessagingStructs.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 26/12/2020.
//

import Foundation
import MapKit

public class LiveMessage: Codable, Identifiable {
    public var id = UUID()
    var recipient: ProtocolAddress
    var expiry: Date
    var error: MessagingControllerError?
    
    init(recipient: ProtocolAddress, expiry: Date, error: Error? = nil) {
        self.recipient = recipient
        self.expiry = expiry
    }
    
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try values.decode(UUID.self, forKey: .id)
        let recipientString = try values.decode(String.self, forKey: .recipientCombinedValue)
        self.recipient = try ProtocolAddress(recipientString)
        self.expiry = try values.decode(Date.self, forKey: .expiry)
        self.error = try values.decodeIfPresent(MessagingControllerError.self, forKey: .expiry)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case recipientCombinedValue
        case expiry
        case error
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(recipient.combinedValue, forKey: .recipientCombinedValue)
        try container.encode(expiry, forKey: .expiry)
        try container.encode(error, forKey: .error)
    }
    
    public var humanReadableExpiry: String {
        let prefixString: String
        if self.expiry < Date() {
            prefixString = "Expired: "
        } else {
            prefixString = "Expires: "
        }
        let dateFormatter = RelativeDateTimeFormatter()
        return prefixString + dateFormatter.localizedString(for: expiry, relativeTo: Date())
    }
}

public struct Location: Codable {
    var latitude: Double
    var longitude: Double
    var liveExpiryDate: Date?
    var time: Date
    
    public var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self.time, relativeTo: Date())
    }
    
    public var toLocationCoordinate: CLLocationCoordinate2D {
        let coordinate = CLLocationCoordinate2D(
            latitude: CLLocationDegrees(self.latitude),
            longitude: CLLocationDegrees(self.longitude)
        )
        return coordinate
    }

}

public class LocationMessage: Codable {
    var id: Int
    var sender: ProtocolAddress
    var location: Location?
    var error: SSAPIEncryptionError?
    
    init(id: Int, sender: ProtocolAddress, location: Location? = nil, error: SSAPIEncryptionError? = nil) {
        self.id = id
        self.sender = sender
        self.location = location
        self.error = error
    }
    
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try values.decode(Int.self, forKey: .id)
        let senderString = try values.decode(String.self, forKey: .senderCombinedValue)
        self.sender = try ProtocolAddress(senderString)
        self.location = try values.decodeIfPresent(Location.self, forKey: .location)
        self.error = try values.decodeIfPresent(SSAPIEncryptionError.self, forKey: .error)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case location
        case senderCombinedValue
        case error
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(location, forKey: .location)
        try container.encode(sender.combinedValue, forKey: .senderCombinedValue)
        try container.encode(error, forKey: .error)
    }
    
    public var toAnnotation: MKPointAnnotation? {
        guard let location = self.location else {
            return nil
        }
        let annotation = MKPointAnnotation()
        annotation.coordinate = location.toLocationCoordinate
        annotation.title = self.sender.name
        return annotation
    }
    
}

public class ShortLocationMessage: Identifiable {
    
    public var id: Int
    var sender: ProtocolAddress
    var time: Date
    var isError: Bool
    var isLive: Bool
    
    init(_ locationMessage: LocationMessage) {
        self.id = locationMessage.id
        self.sender = locationMessage.sender
        self.time = locationMessage.location?.time ?? Date()
        self.isError = locationMessage.error != nil
        self.isLive = locationMessage.location?.liveExpiryDate != nil
    }
    
    public var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self.time, relativeTo: Date())
    }
}
