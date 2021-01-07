//
//  SubscriptionActionSheet.swift
//  DarkMaps (iOS)
//
//  Created by Matthew Roche on 07/01/2021.
//

import SwiftUI
import StoreKit

struct SubscriptionActionSheet: View {
    
    @Binding var isShowing: Bool
    @Binding var subscriptionOptions: [SKProduct]
    
    var subscribe: (_: SKProduct) -> Void
    
    func generateActionSheetButtons(options: [SKProduct]) -> [Alert.Button] {
        let buttons = options.enumerated().map { i, option in
            Alert.Button.default(Text("\(option.localizedTitle): \(option.localizedPrice ?? String(describing: option.price))")) {self.subscribe(option)}
        }
        return buttons
    }
    
    var body: some View {
        Text("").hidden().actionSheet(isPresented: $isShowing) {
            ActionSheet(
                title: Text("Subscribe"),
                message: Text("Choose a subscription type"),
                buttons: generateActionSheetButtons(options: self.subscriptionOptions) + [Alert.Button.cancel()]
            )
        }
    }
}
