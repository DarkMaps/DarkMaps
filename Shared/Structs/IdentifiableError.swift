//
//  IdentifiableError.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 06/12/2020.
//

import Foundation

/// A wrapper for Error allowing it to conform to the Identifiable protocol for global error handling
public struct IdentifiableError: Identifiable {
    public let id = UUID()
    let error: Error
    
    init(_ error: Error) {
        self.error = error
    }
}

