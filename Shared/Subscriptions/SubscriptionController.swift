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
    case invalidIdentifier, unableToRetrieveProductInfo, errorPerformingPurchase, errorVerifyingReceipt, expiredPurchase, neverPurchased, restoreFailed, nothingToRestore
}

public class SubscriptionController {
    
    private let notificationCentre = NotificationCenter.default
    
    public func getSubscriptions(completionHandler: @escaping (Result<[SKProduct], SubscriptionError>) -> ()) {
        SwiftyStoreKit.retrieveProductsInfo(["mtr.DarkMaps.Subscription"]) { result in
            if let product = result.retrievedProducts.first {
                let priceString = product.localizedPrice!
                print("Product: \(product.localizedDescription), price: \(priceString)")
                completionHandler(.success(Array(result.retrievedProducts)))
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
    
    public func purchaseSubscription(product: SKProduct, completionHandler: @escaping (Result<Date, SubscriptionError>) -> ()) {
        SwiftyStoreKit.purchaseProduct(product.productIdentifier, atomically: true) { purchaseResult in
            
            switch purchaseResult {
            case .success(let purchase):
                // Deliver content from server, then:
                if purchase.needsFinishTransaction {
                    SwiftyStoreKit.finishTransaction(purchase.transaction)
                }
                
                let appleValidator = AppleReceiptValidator(service: .sandbox, sharedSecret: Bundle.main.infoDictionary?["STOREKIT_SECRET"] as? String ?? "no storekit secret available")
                SwiftyStoreKit.verifyReceipt(using: appleValidator) { verifyRecieptResult in
                    
                    switch verifyRecieptResult {
                    case .success(let receipt):
                        let verifySubscriptionResult = SwiftyStoreKit.verifySubscription(
                            ofType: .autoRenewable,
                            productId: product.productIdentifier,
                            inReceipt: receipt)
                        
                        switch verifySubscriptionResult {
                        case .purchased(let expiryDate, let receiptItems):
                            print("Product is valid until \(expiryDate)")
                            self.sendSuccessNotification(expiry: expiryDate)
                            completionHandler(.success(expiryDate))
                        case .expired(let expiryDate, let receiptItems):
                            print("Product is expired since \(expiryDate)")
                            self.sendFailureNotification()
                            completionHandler(.failure(.expiredPurchase))
                        case .notPurchased:
                            print("This product has never been purchased")
                            self.sendFailureNotification()
                            completionHandler(.failure(.neverPurchased))
                        }
                    default:
                        completionHandler(.failure(.errorVerifyingReceipt))
                    }
                }
            default:
                completionHandler(.failure(.errorPerformingPurchase))
            }
        }
    }

    
    public func verifyIsStillSubscriber(completionHandler: (Result<Bool, SubscriptionError>) -> ()) {
        completionHandler(.success(true))
    }
    
    
    public func restoreSubscription(completionHandler: @escaping (Result<Void, SubscriptionError>) -> ()) {
        SwiftyStoreKit.restorePurchases(atomically: true) { results in
            if results.restoreFailedPurchases.count > 0 {
                print("Restore Failed: \(results.restoreFailedPurchases)")
                self.sendFailureNotification()
                completionHandler(.failure(.restoreFailed))
            }
            else if results.restoredPurchases.count > 0 {
                print("Restore Success: \(results.restoredPurchases)")
                //Need to find expiry from restoredPurchases
                self.sendSuccessNotification(expiry: Date())
                completionHandler(.success(()))
            }
            else {
                print("Nothing to Restore")
                self.sendFailureNotification()
                completionHandler(.failure(.nothingToRestore))
            }
        }
    }
    
    private func sendFailureNotification() {
        notificationCentre.post(name: .subscriptionController_SubscriptionFailed, object: nil)
    }
    
    private func sendSuccessNotification(expiry: Date) {
        notificationCentre.post(name: .subscriptionController_SubscriptionVerified, object: nil, userInfo: ["expiry": expiry])
    }
    
    
    
}
