//
//  MessagingStructs.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 26/12/2020.
//

import Foundation
import MapKit

public class LiveMessage: Codable {
    var id = UUID()
    var recipient: ProtocolAddress
    var expiry: Int
    
    init(recipient: ProtocolAddress, expiry: Int) {
        self.recipient = recipient
        self.expiry = expiry
    }
    
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try values.decode(UUID.self, forKey: .id)
        let recipientString = try values.decode(String.self, forKey: .recipientCombinedValue)
        self.recipient = try ProtocolAddress(recipientString)
        self.expiry = try values.decode(Int.self, forKey: .expiry)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case recipientCombinedValue
        case expiry
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(recipient.combinedValue, forKey: .recipientCombinedValue)
        try container.encode(expiry, forKey: .expiry)
    }
}

public struct Location: Codable {
    var latitude: Float
    var longitude: Float
}

public class LocationMessage: Codable {
    var id: Int
    var sender: ProtocolAddress
    var location: Location?
    var error: SSAPIEncryptionError?
    var lastReceived: Int
    
    init(id: Int, sender: ProtocolAddress, location: Location? = nil, error: SSAPIEncryptionError? = nil, lastReceived: Int) {
        self.id = id
        self.sender = sender
        self.location = location
        self.lastReceived = lastReceived
    }
    
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try values.decode(Int.self, forKey: .id)
        let senderString = try values.decode(String.self, forKey: .senderCombinedValue)
        self.sender = try ProtocolAddress(senderString)
        self.location = try values.decodeIfPresent(Location.self, forKey: .location)
        self.error = try values.decodeIfPresent(SSAPIEncryptionError.self, forKey: .error)
        self.lastReceived = try values.decode(Int.self, forKey: .lastReceived)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case location
        case senderCombinedValue
        case lastReceived
        case error
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(location, forKey: .location)
        try container.encode(sender.combinedValue, forKey: .senderCombinedValue)
        try container.encode(lastReceived, forKey: .lastReceived)
    }
    
    public var toLocationCoordinate: CLLocationCoordinate2D? {
        guard let location = self.location else {
            return nil
        }
        let coordinate = CLLocationCoordinate2D(
            latitude: CLLocationDegrees(location.latitude),
            longitude: CLLocationDegrees(location.longitude)
        )
        return coordinate
    }
    
    public var toAnnotation: MKPointAnnotation? {
        guard let location = self.location else {
            return nil
        }
        let annotation = MKPointAnnotation()
        annotation.coordinate = self.toLocationCoordinate!
        annotation.title = self.sender.name
        return annotation
    }
}

public class ShortLocationMessage: Identifiable {
    
    public var id: Int
    var sender: ProtocolAddress
    var lastReceived: Int
    
    init(_ locationMessage: LocationMessage) {
        self.id = locationMessage.id
        self.sender = locationMessage.sender
        self.lastReceived = locationMessage.lastReceived
    }
}
