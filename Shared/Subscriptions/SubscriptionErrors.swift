//
//  SubscriptionErrors.swift
//  DarkMaps (iOS)
//
//  Created by Matthew Roche on 10/01/2021.
//

import Foundation

public enum SubscriptionError: LocalizedError {
    case invalidIdentifier, unableToRetrieveProductInfo, errorPerformingPurchase, errorVerifyingReceipt, expiredPurchase, neverPurchased, restoreFailed, nothingToRestore, errorRetreivingReceipts, errorCompletingPurchase, noSubscriptionFound, purchaseCancelled, timedOut
}

extension SubscriptionError {
    
    public var errorDescription: String? {
        switch self {
        case .timedOut:
            return NSLocalizedString("The server didn't repond whilst verifying your purchase. Please try using the 'Restore' button on the settings page. \n\nPlease contact us at the email address below if you think you have been charged and are unable to send live messages. \n\nadmin@dark-maps.net", comment: "")
        case .purchaseCancelled:
            return NSLocalizedString("You cancelled the purchase", comment: "")
        case .invalidIdentifier:
            return NSLocalizedString("Unable to find the specified subscription. \n\nPlease contact us at the email address below if you think you have been charged and are unable to send live messages. \n\nadmin@dark-maps.net", comment: "")
        case .unableToRetrieveProductInfo:
            return NSLocalizedString("Unable to get subscription information from the server.", comment: "")
        case .errorPerformingPurchase:
            return NSLocalizedString("An error occured during purchase.\n\nPlease contact us at the email address below if you think you have been charged and are unable to send live messages. \n\nadmin@dark-maps.net", comment: "")
        case .errorVerifyingReceipt:
            #if DEBUG
                return NSLocalizedString("An error occured whilst trying to verify your purchase.\n\nNB: To test verification you must use the sandbox environment.\n\nPlease contact us at the email address below if you think you have been charged and are unable to send live messages. \n\nadmin@dark-maps.net", comment: "")
            #else
                return NSLocalizedString("An error occured whilst trying to verify your purchase.\n\nPlease contact us at the email address below if you think you have been charged and are unable to send live messages. \n\nadmin@dark-maps.net", comment: "")
            #endif
        case .expiredPurchase:
            return NSLocalizedString("Your subscription has expired.\n\nPlease contact us at the email address below if you think you have been charged and are unable to send live messages. \n\nadmin@dark-maps.net", comment: "")
        case .neverPurchased:
            return NSLocalizedString("You have never purchased a subscription.\n\nPlease contact us at the email address below if you think you have been charged and are unable to send live messages. \n\nadmin@dark-maps.net", comment: "")
        case .restoreFailed:
            return NSLocalizedString("An error occured whilst trying to restore your purchase. \n\nPlease contact us at the email address below if you think you have been charged and are unable to send live messages. \n\nadmin@dark-maps.net", comment: "")
        case .nothingToRestore:
            return NSLocalizedString("There are no purchases to restore.\n\nPlease contact us at the email address below if you think you have been charged and are unable to send live messages. \n\nadmin@dark-maps.net", comment: "")
        case .errorRetreivingReceipts:
            return NSLocalizedString("An error occured whilst retreiving your receipts. \n\nPlease contact us at the email address below if you think you have been charged and are unable to send live messages. \n\nadmin@dark-maps.net", comment: "")
        case .errorCompletingPurchase:
            return NSLocalizedString("An error occured whilst complteting your purchase. \n\nPlease contact us at the email address below if you think you have been charged and are unable to send live messages. \n\nadmin@dark-maps.net", comment: "")
        case .noSubscriptionFound:
            return NSLocalizedString("No subscription to Dark Maps was found. \n\nPlease contact us at the email address below if you think you have been charged and are unable to send live messages. \n\nadmin@dark-maps.net", comment: "")
        }
    }
}
