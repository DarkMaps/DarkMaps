import XCTest
import StoreKitTest

@testable import DarkMaps
import Mockingjay

class SubscriptionTests: XCTestCase {

    override func setUpWithError() throws {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testCanGetSubscriptions() throws {
        
        let expectation = XCTestExpectation(description: "Successfully gets subscription details")
        
        let subscriptionController = SubscriptionController()
        subscriptionController.startObserving()
        
        let session = try SKTestSession(configurationFileNamed: "configuration")
        session.disableDialogs = true
        session.clearTransactions()
        
        subscriptionController.getSubscriptions { getSubscriptionsResult in
            switch getSubscriptionsResult {
            case .success(let products):
                print("Products: \(products)")
                XCTAssertEqual(products.count, 1)
                expectation.fulfill()
            default:
                print("Error in getSubscriptions")
            }
        }
        
        wait(for: [expectation], timeout: 2.0)
        
    }

    func testCanSubscribe() throws {
        
        let expectation = XCTestExpectation(description: "Successfully subscribes")
        
        let subscriptionController = SubscriptionController()
        subscriptionController.startObserving()
        
        let uriValue = "https://buy.itunes.apple.com/verifyReceipt"
        let data: NSDictionary = [
            "receipt": [
                "product_id": "mtr.DarkMaps.Subscription.Monthly",
                "quantity": "1",
                "transaction_id": UUID().uuidString,
                "original_transaction_id": UUID().uuidString,
                "purchase_date_ms": String(Double(Date().timeIntervalSince1970 * 1000)),
                "original_purchase_date_ms": String(format: "%.1f", Double(Date().timeIntervalSince1970 * 1000)),
                "expires_date_ms": String(format: "%.1f", Double(Date().addingTimeInterval(2000).timeIntervalSince1970 * 1000))
            ],
            "status": 0
        ]
        self.stub(uri(uriValue), json(data, status: 200))
        let storedExpiryDate = (data["receipt"]! as! [String: Any])["expires_date_ms"]! as! String
        
        let session = try SKTestSession(configurationFileNamed: "configuration")
        session.disableDialogs = true
        session.askToBuyEnabled = false
        session.clearTransactions()
        
        subscriptionController.getSubscriptions { getSubscriptionsResult in
            switch getSubscriptionsResult {
            case .success(let products):
                subscriptionController.purchaseSubscription(product: products[0]) { purchaseSubscriptionOutcome in
                    
                    switch purchaseSubscriptionOutcome {
                    case .success(let expiryDate):
                      print(expiryDate)
                        XCTAssertEqual(Date(timeIntervalSince1970: (Double(storedExpiryDate)! / 1000)), expiryDate)
                        expectation.fulfill()
                    default:
                        print("Error in purchase subscription")
                    }
                }
            default:
                print("Error in getSubscriptions")
            }
        }
    
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testCanVerifyReceipt() throws {
        let expectation = XCTestExpectation(description: "Successfully subscribes")
        
        let uriValue = "https://sandbox.itunes.apple.com/verifyReceipt"
        let data: NSDictionary = [
            "receipt": [
                "product_id": "mtr.DarkMaps.Subscription.Monthly",
                "quantity": "1",
                "transaction_id": UUID().uuidString,
                "original_transaction_id": UUID().uuidString,
                "purchase_date_ms": String(Double(Date().timeIntervalSince1970 * 1000)),
                "original_purchase_date_ms": String(format: "%.1f", Double(Date().timeIntervalSince1970 * 1000)),
                "expires_date_ms": String(format: "%.1f", Double(Date().addingTimeInterval(2000).timeIntervalSince1970 * 1000))
            ],
            "status": 0
        ]
        let storedExpiryDate = (data["receipt"]! as! [String: Any])["expires_date_ms"]! as! String
        self.stub(uri(uriValue), json(data, status: 200))
        
        let subscriptionController = SubscriptionController()
        subscriptionController.startObserving()
        
        let session = try SKTestSession(configurationFileNamed: "configuration")
        session.disableDialogs = true
        session.askToBuyEnabled = false
        session.clearTransactions()
        
        subscriptionController.verifyReceipt(sandbox: true) { verifyReceiptOutcome in
            switch verifyReceiptOutcome {
            case .success(let expiryDate):
                XCTAssertEqual(Date(timeIntervalSince1970: (Double(storedExpiryDate)! / 1000)), expiryDate)
                expectation.fulfill()
            default:
                print("Error in verifyReceipt")
            }
        }
    
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testCanRestore() throws {
        let expectation = XCTestExpectation(description: "Successfully subscribes")
        
        let uriValue = "https://buy.itunes.apple.com/verifyReceipt"
        let data: NSDictionary = [
            "receipt": [
                "product_id": "mtr.DarkMaps.Subscription.Monthly",
                "quantity": "1",
                "transaction_id": UUID().uuidString,
                "original_transaction_id": UUID().uuidString,
                "purchase_date_ms": String(Double(Date().timeIntervalSince1970 * 1000)),
                "original_purchase_date_ms": String(format: "%.1f", Double(Date().timeIntervalSince1970 * 1000)),
                "expires_date_ms": String(format: "%.1f", Double(Date().addingTimeInterval(2000).timeIntervalSince1970 * 1000))
            ],
            "status": 0
        ]
        let storedExpiryDate = (data["receipt"]! as! [String: Any])["expires_date_ms"]! as! String
        self.stub(uri(uriValue), json(data, status: 200))
        
        let subscriptionController = SubscriptionController()
        subscriptionController.startObserving()
        
        let session = try SKTestSession(configurationFileNamed: "configuration")
        session.disableDialogs = true
        session.askToBuyEnabled = false
        session.clearTransactions()
        try session.buyProduct(productIdentifier: "mtr.DarkMaps.Subscription.Monthly")
        
        subscriptionController.restorePurchases { restoreOutcome in
            switch restoreOutcome {
            case .success(let expiryDate):
                XCTAssertEqual(Date(timeIntervalSince1970: (Double(storedExpiryDate)! / 1000)), expiryDate)
                expectation.fulfill()
            default:
                print("Error in verifyReceipt")
            }
        }
    
        wait(for: [expectation], timeout: 5.0)
    }
    
}


