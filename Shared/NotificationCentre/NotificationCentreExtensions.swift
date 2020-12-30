//
//  NotificationCentreExtensions.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 29/12/2020.
//

import Foundation

extension Notification.Name {
    static let messagingStore_LiveMessagesUpdates = Notification.Name("MessagingStore.LiveMessagesUpdated")
    static let locationController_NewLocationReceived = Notification.Name("LocationController.NewLocationReceived")
}
