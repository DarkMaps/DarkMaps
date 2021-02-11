//
//  ErrorAlert.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 06/12/2020.
//

import SwiftUI

public func ErrorAlert(viewError: IdentifiableError) -> Alert {
    return Alert(
        title: Text("Error"),
        message: Text(viewError.error.localizedDescription),
        dismissButton: .default(Text("OK"))
    )
}
