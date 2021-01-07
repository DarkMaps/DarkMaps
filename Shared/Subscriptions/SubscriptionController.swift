//
//  SubscriptionController.swift
//  DarkMaps (iOS)
//
//  Created by Matthew Roche on 30/12/2020.
//

import Foundation
import SwiftyStoreKit
import StoreKit
import TPInAppReceipt

public enum SubscriptionError: LocalizedError {
    case invalidIdentifier, unableToRetrieveProductInfo, errorPerformingPurchase, errorVerifyingReceipt, expiredPurchase, neverPurchased, restoreFailed, nothingToRestore, errorRetreivingReceipts, errorCompletingPurchase
}

public class SubscriptionController {
    
    private let productArray = Set(["mtr.DarkMaps.Subscription.Monthly"])
    private let notificationCentre = NotificationCenter.default
    
    public func getSubscriptions(completionHandler: @escaping (Result<[SKProduct], SubscriptionError>) -> ()) {
        print("Getting subscription options")
        SwiftyStoreKit.retrieveProductsInfo(productArray) { result in
            if let product = result.retrievedProducts.first {
                print("Successsfully retrieved options")
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
            print(purchaseResult)
            switch purchaseResult {
            case .success(let purchase):
                print("Purchase successful")
                // Deliver content from server, then:
                if purchase.needsFinishTransaction {
                    SwiftyStoreKit.finishTransaction(purchase.transaction)
                    print("Finished transaction")
                }
                
                self.verifyReceiptLocally() { verifyResult in
                    switch verifyResult {
                    case .success(let expiryDate):
                        print("Successfully verified")
                        completionHandler(.success(expiryDate))
                    case .failure(let error):
                        print("Error verifying")
                        completionHandler(.failure(error))
                    }
                }
            default:
                print("Error performing purchase")
                completionHandler(.failure(.errorPerformingPurchase))
            }
        }
    }

    
    public func verifyIsStillSubscriber(completionHandler: @escaping (Result<Date, SubscriptionError>) -> ()) {
        InAppReceipt.refresh { (error) in
            if let err = error {
                print("Fetch receipt failed: \(err.localizedDescription)")
                completionHandler(.failure(.errorRetreivingReceipts))
            } else {
                self.verifyReceiptLocally() { verifyResult in
                    switch verifyResult {
                    case .success(let expiryDate):
                        completionHandler(.success(expiryDate))
                    case .failure(let error):
                        completionHandler(.failure(error))
                    }
                }
            }
        }
    }
    
    private func verifyReceiptLocally(completionHandler: @escaping (Result<Date, SubscriptionError>) -> ()) {
        if let receipt = try? InAppReceipt.localReceipt() {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd MMM yyyy"
            print(String(decoding: receipt.payloadRawData, as: UTF8.self))
            for purchase in receipt.activeAutoRenewableSubscriptionPurchases {
                print(purchase.productIdentifier)
                print(purchase.subscriptionExpirationDate)
                if self.productArray.contains(purchase.productIdentifier) {
                    do {
                        try receipt.verify()
                        guard let expirationDate = purchase.subscriptionExpirationDate else {
                            self.sendFailureNotification()
                            completionHandler(.failure(.errorVerifyingReceipt))
                            return
                        }
                        self.sendSuccessNotification(expiry: expirationDate)
                        completionHandler(.success(expirationDate))
                        return
                    } catch {
                        self.sendFailureNotification()
                        completionHandler(.failure(.errorVerifyingReceipt))
                    }
                }
            }
        } else {
            self.sendFailureNotification()
            completionHandler(.failure(.errorVerifyingReceipt))
        }
    }
    
    private func verifyReceipt(completionHandler: @escaping (Result<Date, SubscriptionError>) -> ()) {
        
        let sharedSecret = Bundle.main.infoDictionary?["STOREKIT_SECRET"] as? String ?? "no storekit secret available"
        let appleValidator = AppleReceiptValidator(service: .sandbox, sharedSecret: sharedSecret)
        print("Verifying with secret: \(sharedSecret)")
        SwiftyStoreKit.verifyReceipt(using: appleValidator) { verifyReceiptResult in
            print(verifyReceiptResult)
            switch verifyReceiptResult {
            case .success(let receipt):
                        
                let verifySubscriptionResult = SwiftyStoreKit.verifySubscriptions(
                    ofType: .autoRenewable,
                    productIds: self.productArray,
                    inReceipt: receipt)
                
                switch verifySubscriptionResult {
                case .purchased(let expiryDate, _):
                    print("Product is valid until \(expiryDate)")
                    self.sendSuccessNotification(expiry: expiryDate)
                    completionHandler(.success(expiryDate))
                case .expired(let expiryDate, _):
                    print("Product is expired since \(expiryDate)")
                    self.sendFailureNotification()
                    completionHandler(.failure(.expiredPurchase))
                case .notPurchased:
                    print("This product has never been purchased")
                    self.sendFailureNotification()
                    completionHandler(.failure(.neverPurchased))
                }
                
            case .error(let error):
                print(error)
                completionHandler(.failure(.errorVerifyingReceipt))
            }
        }
    }
    
    public func handleCompleteTransactions(completionHandler: @escaping (Result<Date, SubscriptionError>) -> ()) {
        SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
            for purchase in purchases {
                switch purchase.transaction.transactionState {
                case .purchased, .restored:
                    if purchase.needsFinishTransaction {
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
                    self.verifyReceiptLocally() { verifyReceiptResult in
                        switch verifyReceiptResult {
                        case .success(let expiryDate):
                            completionHandler(.success(expiryDate))
                        case .failure(let error):
                            completionHandler(.failure(error))
                        }
                    }
                default:
                    completionHandler(.failure(.nothingToRestore))
                }
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
