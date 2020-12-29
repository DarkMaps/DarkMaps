//
//  RootView.swift
//  SignalMaps (iOS)
//
//  Created by Matthew Roche on 05/12/2020.
//

import Foundation

class AppState: ObservableObject {
    @Published var loggedInUser: LoggedInUser? = nil {
        didSet {
            handleNewUser()
        }
    }
    @Published var displayedError: IdentifiableError? = nil
    @Published var locationController = LocationController()
    
    func handleNewUser() {
        if self.loggedInUser == nil {
            KeychainSwift().delete("loggedInUser")
        } else {
            let encoder = JSONEncoder()
            guard let data = try? encoder.encode(self.loggedInUser) else {
                print("Error encoding object")
                self.loggedInUser = nil
                return
            }
            KeychainSwift().set(data, forKey: "loggedInUser")
        }
    }
    
//    func handleRestartLiveMessages() {
//        if let loggedInUser = self.loggedInUser {
//            do {
//                let messagingController = try MessagingController(userName: loggedInUser.userName)
//                let liveMessagesArray = try messagingController.getLiveMessageRecipients()
//                if liveMessagesArray.count > 0 {
//                    locationController.startLocationUpdates()
//                } else {
//                    locationController.stopLocationUpdates()
//                }
//            } catch {
//                print("Error loading live messages")
//                return
//            }
//            
//        }
//    }
}
