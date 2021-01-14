//
//  SimpleSignalSwiftExtensions.swift
//  DarkMaps
//
//  Created by Matthew Roche on 14/01/2021.
//

import Foundation

extension Collection {
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension ProtocolAddress: Identifiable {
    
    convenience init(_ combinedValue: String) throws {
        let splitValues = combinedValue.split(separator: ".")
        guard let deviceIdString = splitValues.last else {
            throw SSAPIProtocolAddressError.incorrectNumberOfComponents
        }
        guard let deviceId = UInt32(deviceIdString) else {
            throw SSAPIProtocolAddressError.deviceIdIsNotInt
        }
        let name = combinedValue.replacingOccurrences(of: ".\(deviceIdString)", with: "")
        try self.init(name: name, deviceId: deviceId)
    }
    
    var combinedValue: String {
        return "\(self.name).\(self.deviceId)"
    }
}

extension Date {
    init(ticks: UInt64) {
        let intervalSince1970 = Double((ticks / 10_000_000) - 62_135_596_800)
        self.init(timeIntervalSince1970: intervalSince1970)
    }
    var ticks: UInt64 {
        return UInt64((self.timeIntervalSince1970 + 62_135_596_800) * 10_000_000)
    }
}

extension Array where Element == UInt8 {
    func toBase64String() -> String {
        let data = NSData(bytes: self, length: self.count)
        let base64String = data.base64EncodedString(options: NSData.Base64EncodingOptions.endLineWithLineFeed)
        return base64String
    }
}

extension String {
    func toUint8Array() -> [UInt8]? {
        guard let data = Data.init(base64Encoded: self, options: []) else {
            return nil
        }
        return [UInt8](data)
    }
}
