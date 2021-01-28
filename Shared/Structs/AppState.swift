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
    let subscriptionController = SubscriptionController()
    @Published var subscriptionSheetIsShowing = false
    @Published var displayedError: IdentifiableError? = nil
    
    var locationController = LocationController()
    
    func handleNewUser() {
        print("Storing new user details")
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
