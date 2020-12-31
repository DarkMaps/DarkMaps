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
    case invalidIdentifier, unableToRetrieveProductInfo, errorPerformingPurchase, errorVerifyingReceipt, expiredPurchase, neverPurchased, restoreFailed, nothingToRestore, errorRetreivingReceipts
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
                
                self.verifyReceipt() { verifyResult in
                    switch verifyResult {
                    case .success(let expiryDate):
                        completionHandler(.success(expiryDate))
                    case .failure(let error):
                        completionHandler(.failure(error))
                    }
                }
            default:
                completionHandler(.failure(.errorPerformingPurchase))
            }
        }
    }

    
    public func verifyIsStillSubscriber(completionHandler: @escaping (Result<Date, SubscriptionError>) -> ()) {
        SwiftyStoreKit.fetchReceipt(forceRefresh: true) { result in
            switch result {
            case .success(let receiptData):
                let encryptedReceipt = receiptData.base64EncodedString(options: [])
                print("Fetch receipt success:\n\(encryptedReceipt)")
                
                self.verifyReceipt() { verifyResult in
                    switch verifyResult {
                    case .success(let expiryDate):
                        completionHandler(.success(expiryDate))
                    case .failure(let error):
                        completionHandler(.failure(error))
                    }
                }
                
            case .error(let error):
                print("Fetch receipt failed: \(error)")
                completionHandler(.failure(.errorRetreivingReceipts))
            }
        }
    }
    
    private func verifyReceipt(completionHandler: @escaping (Result<Date, SubscriptionError>) -> ()) {
        
        let sharedSecret = Bundle.main.infoDictionary?["STOREKIT_SECRET"] as? String ?? "no storekit secret available"
        let appleValidator = AppleReceiptValidator(service: .sandbox, sharedSecret: sharedSecret)
        print("Verifying with secret: \(sharedSecret)")
        SwiftyStoreKit.verifyReceipt(using: appleValidator) { verifyRecieptResult in
            
            switch verifyRecieptResult {
            case .success(let receipt):
                
                self.getSubscriptions() { getSubscriptionsResult in
                    switch getSubscriptionsResult {
                    case .success(let productArray):
                        
                        let productIds = Set(productArray.map({$0.productIdentifier}))
                        
                        let verifySubscriptionResult = SwiftyStoreKit.verifySubscriptions(
                            ofType: .autoRenewable,
                            productIds: productIds,
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
                    case .failure(let error):
                        completionHandler(.failure(error))
                    }
                }
            default:
                completionHandler(.failure(.errorVerifyingReceipt))
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
