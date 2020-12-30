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
    var messagingController: MessagingController? = nil
    @Published var displayedError: IdentifiableError? = nil
    
    var locationController = LocationController()
    
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
}
