/// Copyright (c) 2018 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

// Below is heavily indebted to https://github.com/bizz84/SwiftyStoreKit and https://www.raywenderlich.com/1458378-in-app-purchase-tutorial-auto-renewable-subscriptions#toc-anchor-001

import StoreKit

public typealias ProductID = String
public typealias ProductsRequestCompletionHandler = (Result<[SKProduct], SubscriptionError>) -> Void
public typealias ProductPurchaseCompletionHandler = (Result<Date, SubscriptionError>) -> Void

// MARK: - SubscriptionController
public class SubscriptionController: NSObject  {
    private let productIDs = Set(["mtr.DarkMaps.Subscription.Monthly"])
    private var productsRequest: SKProductsRequest?
    private var productsRequestCompletionHandler: ProductsRequestCompletionHandler?
    private var productPurchaseCompletionHandler: ProductPurchaseCompletionHandler?
    private let notificationCentre = NotificationCenter.default
    
    private func sendFailureNotification() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {return}
            self.notificationCentre.post(name: .subscriptionController_SubscriptionFailed, object: nil)
        }
    }

    private func sendSuccessNotification(expiry: Date) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {return}
            self.notificationCentre.post(name: .subscriptionController_SubscriptionVerified, object: nil, userInfo: ["expiry": expiry])
        }
    }
    
    func startObserving() {
        SKPaymentQueue.default().add(self)
    }
     
     
    func stopObserving() {
        SKPaymentQueue.default().remove(self)
    }
}

// MARK: - StoreKit API
extension SubscriptionController {
    
    public func getSubscriptions(_ completionHandler: @escaping ProductsRequestCompletionHandler) {
        productsRequest?.cancel()
        productsRequestCompletionHandler = completionHandler

        productsRequest = SKProductsRequest(productIdentifiers: productIDs)
        productsRequest!.delegate = self
        productsRequest!.start()
    }

    public func purchaseSubscription(product: SKProduct, _ completionHandler: @escaping ProductPurchaseCompletionHandler) {
        productPurchaseCompletionHandler = completionHandler
        print("Buying \(product.productIdentifier)...")
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }

    public class func canMakePayments() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }

    public func restorePurchases(_ completionHandler: @escaping ProductPurchaseCompletionHandler) {
        productPurchaseCompletionHandler = completionHandler
        print("Restoring...")
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    private func refreshReceipt() {
        let request = SKReceiptRefreshRequest()
        request.delegate = self // to be able to receive the results of this request, check the SKRequestDelegate protocol
        request.start()
    }
}

// MARK: - SKProductsRequestDelegate
extension SubscriptionController: SKProductsRequestDelegate {
  public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
    print("Loaded list of products...")
    let products = response.products
    guard !products.isEmpty else {
      print("Product list is empty...!")
      print("Did you configure the project and set up the IAP?")
        productsRequestCompletionHandler?(.failure(.unableToRetrieveProductInfo))
      return
    }
    for p in products {
      print("Found product: \(p.productIdentifier) \(p.localizedTitle) \(p.price.floatValue)")
    }
    productsRequestCompletionHandler?(.success(products))
    clearRequestAndHandler()
  }

  public func request(_ request: SKRequest, didFailWithError error: Error) {
    print("Failed to load list of products.")
    print("Error: \(error.localizedDescription)")
    productsRequestCompletionHandler?(.failure(.unableToRetrieveProductInfo))
    clearRequestAndHandler()
  }

  private func clearRequestAndHandler() {
    productsRequest = nil
    productsRequestCompletionHandler = nil
  }
}

// MARK: - SKPaymentTransactionObserver
extension SubscriptionController: SKPaymentTransactionObserver {
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        print("Got transactions")
        for transaction in transactions {
            switch (transaction.transactionState) {
            case .purchased:
                complete(transaction: transaction)
                break
            case .failed:
                fail(transaction: transaction)
                break
            case .restored:
                restore(transaction: transaction)
                break
            case .deferred:
                break
            case .purchasing:
                break
            @unknown default:
                fail()
            }
        }
    }
    
    // Handling failed restore.
    public func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Swift.Error) {
        fail(error: error)
    }

    private func complete(transaction: SKPaymentTransaction) {
        print("complete...")
        productPurchaseCompleted(identifier: transaction.payment.productIdentifier)
        SKPaymentQueue.default().finishTransaction(transaction)
    }

    private func restore(transaction: SKPaymentTransaction) {
        guard let productIdentifier = transaction.original?.payment.productIdentifier else { return }
        print("restore... \(productIdentifier)")
        productPurchaseCompleted(identifier: productIdentifier)
        SKPaymentQueue.default().finishTransaction(transaction)
    }

    private func fail(transaction: SKPaymentTransaction? = nil, error: Error? = nil) {
        print("fail...")
        if let transaction = transaction,
           let transactionError = transaction.error as NSError? {
            if let localizedDescription = transaction.error?.localizedDescription,
               transactionError.code != SKError.paymentCancelled.rawValue {
                   print("Transaction Error: \(localizedDescription)")
                   sendFailureNotification()
                   productPurchaseCompletionHandler?(.failure(.errorCompletingPurchase))
            } else {
                //Transaction was cancelled
                sendFailureNotification()
                productPurchaseCompletionHandler?(.failure(.purchaseCancelled))
            }
        }
        if let transaction = transaction {
            SKPaymentQueue.default().finishTransaction(transaction)
        }
        clearHandler()
    }

    private func productPurchaseCompleted(identifier: ProductID?) {
        guard let identifier = identifier else { return }
        print("Purchase of \(identifier) complete")
        self.verifyReceipt { [weak self] verificationResult in
            guard let self = self else {return}
            switch verificationResult {
            case .success(let expiryDate):
                self.sendSuccessNotification(expiry: expiryDate)
                self.productPurchaseCompletionHandler?(.success(expiryDate))
                self.clearHandler()
            case .failure(let error):
                print(error)
                self.productPurchaseCompletionHandler?(.failure(error))
            }
        }
        
    }

    private func clearHandler() {
        productPurchaseCompletionHandler = nil
    }
    
}

extension SubscriptionController {
    
    // Here we send the receipt to Apple for verification. Best practice is to do this on server, and in the future we could use a Lambda
    public func verifyReceipt(sandbox: Bool = false, completionHandler: @escaping (Result<Date, SubscriptionError>) -> ()) {
        
        do {
            
            #if DEBUG
                //Verification impossible on simulator
                #if targetEnvironment(simulator)
                    //Only run if in DEBUG on simulator and not testing
                    if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil {
                        print("********************* DEBUG MODE ********************************")
                        print("********************* SKIPPING VERIFICATION *********************")
                        print("********************* NOT IN PRODUCTION *************************")
                        completionHandler(.success(Date().addingTimeInterval(2000)))
                        return
                    }
                
                #endif
            #endif
            
            let sharedSecret = Bundle.main.infoDictionary?["STOREKIT_SECRET"] as? String ?? "no storekit secret available"
            guard let appStoreReceiptURL = Bundle.main.appStoreReceiptURL, FileManager.default.fileExists(atPath: appStoreReceiptURL.path) else {
                print("Unable to get app store receipt")
                self.refreshReceipt()
                return
            }
            let receiptData = try Data(contentsOf: appStoreReceiptURL, options: .alwaysMapped)
            let receiptString = receiptData.base64EncodedString(options: [.endLineWithCarriageReturn])
            let dict = ["receipt-data" : receiptString, "password" : sharedSecret] as [String : Any]
            let jsonData = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)

            guard let storeURL = Foundation.URL(string:"https://buy.itunes.apple.com/verifyReceipt"),
                  let sandboxURL = Foundation.URL(string: "https://sandbox.itunes.apple.com/verifyReceipt") else {
                completionHandler(.failure(.errorVerifyingReceipt))
                return
            }
            
            var request = URLRequest(url: sandbox ? sandboxURL : storeURL)
            request.httpMethod = "POST"
            request.httpBody = jsonData
            let session = URLSession(configuration: URLSessionConfiguration.default)
            
            let semaphore = DispatchSemaphore(value: 0)
            
            session.dataTask(with: request) { data, response, error in
                
                do {
                    guard let receivedData = data, let httpResponse = response as? HTTPURLResponse, error == nil, httpResponse.statusCode == 200  else {
                        print("Unable to parse response")
                        completionHandler(.failure(.errorVerifyingReceipt))
                        return
                    }
                    
                    guard let jsonResponse = try JSONSerialization.jsonObject(with: receivedData, options: JSONSerialization.ReadingOptions.mutableContainers) as? Dictionary<String, AnyObject>,
                        let status = jsonResponse["status"] as? Int64 else {
                        print("Unable to parse data")
                        completionHandler(.failure(.errorVerifyingReceipt))
                        return
                    }
                    
                    switch status {
                    case 0:
                        guard let allReceiptData = jsonResponse["receipt"] as? [String: Any],
                              let allReceipts = allReceiptData["in_app"] as? [ReceiptInfo],
                              let latestReceipt = allReceipts.last,
                              let decodedReceipt = ReceiptItem(receiptInfo: latestReceipt),
                              let subscriptionExpirationDate = decodedReceipt.subscriptionExpirationDate else {
                            completionHandler(.failure(.errorVerifyingReceipt))
                            return
                        }
                        if (subscriptionExpirationDate > Date()) {
                            print("Subscription successfully verified: expires \(String(describing: (latestReceipt as [String: Any])["expires_date"] ?? "Unable to get expiry date"))")
                            completionHandler(.success(subscriptionExpirationDate))
                        } else {
                            print("Subscription expired: \(String(describing: (latestReceipt as [String: Any])["expires_date"] ?? "Unable to get expiry date"))")
                            completionHandler(.failure(.expiredPurchase))
                        }
                        
                    case 21007:
                        // Means we are in sandbox env.
                        self.verifyReceipt(sandbox: true, completionHandler: completionHandler)
                    default:
                        print("Unrecognised response")
                        print(status)
                        completionHandler(.failure(.errorVerifyingReceipt))
                    }
                } catch {
                    print("Error occured")
                    print(error)
                    completionHandler(.failure(.errorVerifyingReceipt))
                }
                semaphore.signal()
            }.resume()
            
            if semaphore.wait(timeout: (DispatchTime.now() + 5)) == .timedOut {
                completionHandler(.failure(.timedOut))
            }
            
        } catch {
            completionHandler(.failure(.errorVerifyingReceipt))
        }
    }
    
}
