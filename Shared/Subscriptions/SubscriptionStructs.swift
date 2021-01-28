//
//  SubscriptionStructs.swift
//  DarkMaps (iOS)
//
//  Created by Matthew Roche on 28/01/2021.
//

// Below is heavily indebted to https://github.com/bizz84/SwiftyStoreKit

import Foundation
import StoreKit

public typealias ReceiptInfo = [String: AnyObject]

public struct ReceiptItem: Codable {
    public var productId: String
    public var quantity: Int
    public var transactionId: String
    public var originalTransactionId: String
    public var purchaseDate: Date
    public var originalPurchaseDate: Date
    public var webOrderLineItemId: String?
    public var subscriptionExpirationDate: Date?
    public var cancellationDate: Date?
    public var isTrialPeriod: Bool
    public var isInIntroOfferPeriod: Bool
    
    public init(productId: String, quantity: Int, transactionId: String, originalTransactionId: String, purchaseDate: Date, originalPurchaseDate: Date, webOrderLineItemId: String?, subscriptionExpirationDate: Date?, cancellationDate: Date?, isTrialPeriod: Bool, isInIntroOfferPeriod: Bool) {
        self.productId = productId
        self.quantity = quantity
        self.transactionId = transactionId
        self.originalTransactionId = originalTransactionId
        self.purchaseDate = purchaseDate
        self.originalPurchaseDate = originalPurchaseDate
        self.webOrderLineItemId = webOrderLineItemId
        self.subscriptionExpirationDate = subscriptionExpirationDate
        self.cancellationDate = cancellationDate
        self.isTrialPeriod = isTrialPeriod
        self.isInIntroOfferPeriod = isInIntroOfferPeriod
    }
    
    public init?(receiptInfo: ReceiptInfo) {
            guard
                let productId = receiptInfo["product_id"] as? String,
                let quantityString = receiptInfo["quantity"] as? String,
                let quantity = Int(quantityString),
                let transactionId = receiptInfo["transaction_id"] as? String,
                let originalTransactionId = receiptInfo["original_transaction_id"] as? String,
                let purchaseDate = ReceiptItem.parseDate(from: receiptInfo, key: "purchase_date_ms"),
                let originalPurchaseDate = ReceiptItem.parseDate(from: receiptInfo, key: "original_purchase_date_ms")
                else {
                    print("could not parse receipt item: \(receiptInfo). Skipping...")
                    return nil
            }
        
            self.productId = productId
            self.quantity = quantity
            self.transactionId = transactionId
            self.originalTransactionId = originalTransactionId
            self.purchaseDate = purchaseDate
            self.originalPurchaseDate = originalPurchaseDate
            self.webOrderLineItemId = receiptInfo["web_order_line_item_id"] as? String
            self.subscriptionExpirationDate = ReceiptItem.parseDate(from: receiptInfo, key: "expires_date_ms")
            self.cancellationDate = ReceiptItem.parseDate(from: receiptInfo, key: "cancellation_date_ms")
            if let isTrialPeriod = receiptInfo["is_trial_period"] as? String {
                self.isTrialPeriod = Bool(isTrialPeriod) ?? false
            } else {
                self.isTrialPeriod = false
            }
            if let isInIntroOfferPeriod = receiptInfo["is_in_intro_offer_period"] as? String {
                self.isInIntroOfferPeriod = Bool(isInIntroOfferPeriod) ?? false
            } else {
                self.isInIntroOfferPeriod = false
            }
        }

        private static func parseDate(from receiptInfo: ReceiptInfo, key: String) -> Date? {
            guard
                let requestDateString = receiptInfo[key] as? String,
                let requestDateMs = Double(requestDateString) else {
                    return nil
            }
            return Date(timeIntervalSince1970: requestDateMs / 1000)
        }
}

extension SKProduct {
    
    var localizedPrice: String? {
            return priceFormatter(locale: priceLocale).string(from: price)
        }
        
        private func priceFormatter(locale: Locale) -> NumberFormatter {
            let formatter = NumberFormatter()
            formatter.locale = locale
            formatter.numberStyle = .currency
            return formatter
        }
    
    var localizedSubscriptionPeriod: String {
        guard let subscriptionPeriod = self.subscriptionPeriod else { return "" }
        
        let dateComponents: DateComponents
        
        switch subscriptionPeriod.unit {
        case .day: dateComponents = DateComponents(day: subscriptionPeriod.numberOfUnits)
        case .week: dateComponents = DateComponents(weekOfMonth: subscriptionPeriod.numberOfUnits)
        case .month: dateComponents = DateComponents(month: subscriptionPeriod.numberOfUnits)
        case .year: dateComponents = DateComponents(year: subscriptionPeriod.numberOfUnits)
        @unknown default:
            // Default to month units in the unlikely event a different unit type is added to a future OS version
            dateComponents = DateComponents(month: subscriptionPeriod.numberOfUnits)
        }

        return DateComponentsFormatter.localizedString(from: dateComponents, unitsStyle: .spellOut) ?? ""
    }
}
