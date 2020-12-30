//
//  SubscriptionController.swift
//  DarkMaps (iOS)
//
//  Created by Matthew Roche on 30/12/2020.
//

import Foundation
import SwiftyStoreKit
import StoreKit

public enum SubscriptionError: LocalizedError {
    case invalidIdentifier, unableToRetrieveProductInfo
}

public class SubscriptionController {
    
    public func getSubscriptions(completionHandler: @escaping (Result<SKProduct, SubscriptionError>) -> ()) {
        SwiftyStoreKit.retrieveProductsInfo(["mtr.DarkMaps.Subscription.Monthly"]) { result in
            if let product = result.retrievedProducts.first {
                let priceString = product.localizedPrice!
                print("Product: \(product.localizedDescription), price: \(priceString)")
                completionHandler(.success(product))
            }
            else if let invalidProductId = result.invalidProductIDs.first {
                print("Invalid product identifier: \(invalidProductId)")
                completionHandler(.failure(.invalidIdentifier))
            }
            else {
                print("Error: \(String(describing: result.error))")
                completionHandler(.failure(.unableToRetrieveProductInfo))
            }
        }
    }
    
}
