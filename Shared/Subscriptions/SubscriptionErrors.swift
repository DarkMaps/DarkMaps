//
//  SubscriptionErrors.swift
//  DarkMaps (iOS)
//
//  Created by Matthew Roche on 10/01/2021.
//

import Foundation

public enum SubscriptionError: LocalizedError {
    case invalidIdentifier, unableToRetrieveProductInfo, errorPerformingPurchase, errorVerifyingReceipt, expiredPurchase, neverPurchased, restoreFailed, nothingToRestore, errorRetreivingReceipts, errorCompletingPurchase, noSubscriptionFound
}

extension SubscriptionError {
    
    public var errorDescription: String? {
        switch self {
        case .invalidIdentifier:
            return NSLocalizedString("Unable to find the specified subscription. \n\nPlease contact us at the email address below if you think you have been charged and are unable to send live messages. \n\nadmin@dark-maps.com", comment: "")
        case .unableToRetrieveProductInfo:
            return NSLocalizedString("Unable to get subscription information from the server.", comment: "")
        case .errorPerformingPurchase:
            return NSLocalizedString("An error occured during purchase.\n\nPlease contact us at the email address below if you think you have been charged and are unable to send live messages. \n\nadmin@dark-maps.com", comment: "")
        case .errorVerifyingReceipt:
            return NSLocalizedString("An error occured whilst trying to verify your purchase.\n\nPlease contact us at the email address below if you think you have been charged and are unable to send live messages. \n\nadmin@dark-maps.com", comment: "")
        case .expiredPurchase:
            return NSLocalizedString("Your subscription has expired.\n\nPlease contact us at the email address below if you think you have been charged and are unable to send live messages. \n\nadmin@dark-maps.com", comment: "")
        case .neverPurchased:
            return NSLocalizedString("You have never purchased a subscription.\n\nPlease contact us at the email address below if you think you have been charged and are unable to send live messages. \n\nadmin@dark-maps.com", comment: "")
        case .restoreFailed:
            return NSLocalizedString("An error occured whilst trying to restore your purchase. \n\nPlease contact us at the email address below if you think you have been charged and are unable to send live messages. \n\nadmin@dark-maps.com", comment: "")
        case .nothingToRestore:
            return NSLocalizedString("There are no purchases to restore.\n\nPlease contact us at the email address below if you think you have been charged and are unable to send live messages. \n\nadmin@dark-maps.com", comment: "")
        case .errorRetreivingReceipts:
            return NSLocalizedString("An error occured whilst retreiving your receipts. \n\nPlease contact us at the email address below if you think you have been charged and are unable to send live messages. \n\nadmin@dark-maps.com", comment: "")
        case .errorCompletingPurchase:
            return NSLocalizedString("An error occured whilst complteting your purchase. \n\nPlease contact us at the email address below if you think you have been charged and are unable to send live messages. \n\nadmin@dark-maps.com", comment: "")
        case .noSubscriptionFound:
            return NSLocalizedString("No subscription to Dark Maps was found. \n\nPlease contact us at the email address below if you think you have been charged and are unable to send live messages. \n\nadmin@dark-maps.com", comment: "")
        }
    }
}
