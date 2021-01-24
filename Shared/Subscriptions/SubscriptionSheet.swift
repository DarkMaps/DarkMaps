//
//  SubscriptionSheet.swift
//  DarkMaps
//
//  Created by Matthew Roche on 17/01/2021.
//

import SwiftUI
import StoreKit

struct SubscriptionSheet: View {
    
    @EnvironmentObject var appState: AppState
    
    @State var subscribeInProgress = false
    @State var subscriptionOptions: [SKProduct] = []
    
    var subscriptionController = SubscriptionController()
    
    let features: [String: String] = [
        "Live Messages": "Send messages for a specified period of time, even whilst Dark Maps is in the background.",
        "Support development": "Help us to keep the servers running and develop new features",
        "Security audit": "Help us to fund an audit of the Dark Maps app and server"
    ]
    
    func getSubscriptionOptions() {
        subscriptionController.getSubscriptions() { result in
            switch result {
            case .success(let options):
                self.subscriptionOptions = options
            case .failure(let error):
                appState.subscriptionSheetIsShowing = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    appState.displayedError = IdentifiableError(error)
                }
            }
        }
    }
    
    func subscribe(product: SKProduct) {
        subscribeInProgress = true
        subscriptionController.purchaseSubscription(product: product) { result in
            subscribeInProgress = false
            switch result {
            case .success(let date):
                print(date)
            case .failure(let error):
                appState.subscriptionSheetIsShowing = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    appState.displayedError = IdentifiableError(error)
                }
            }
        }
    }
    
    func restoreSubscription() {
        subscribeInProgress = true
        subscriptionController.verifyIsStillSubscriber() { result in
            subscribeInProgress = false
            switch result {
            case .success(let expiryDate):
                print("Expiry date: \(expiryDate.timeIntervalSince1970)")
                return
            case .failure(let error):
                appState.subscriptionSheetIsShowing = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    appState.displayedError = IdentifiableError(error)
                }
            }
        }
    }
    
    
    func getSubscriptionText(_ product: SKProduct) -> String {
        return product.localizedPrice ?? product.price.description
    }
    
    var body: some View {
        VStack {
            VStack {
                Text("Dark Maps Subscription").font(.largeTitle)
                Text("Subscribe to Dark Maps to access the benefits below. You can cancel any time you wish from within the settings menu.").padding(.horizontal)
            }
            VStack {
                TabView {
                    ForEach(features.sorted(by: <), id: \.key) { title, description in
                        ZStack {
                            LinearGradient(gradient: Gradient(colors: [Color("GradientColor"), Color.accentColor]), startPoint: .leading, endPoint: .trailing)
                            VStack {
                                Text("\(title)").foregroundColor(.white).font(.title)
                                Divider().background(Color.white)
                                Spacer()
                                Text("\(description)").foregroundColor(.white)
                            }.padding().padding(.bottom, 40)
                        }.clipShape(RoundedRectangle(cornerRadius: 10.0, style: .continuous))
                    }
                    .padding(.all, 10)
                }
                .frame(width: UIScreen.main.bounds.width, height: 200)
                .tabViewStyle(PageTabViewStyle())
                Spacer()
                Divider().background(Color.accentColor)
            }
            if subscriptionOptions.count > 0 {
                VStack {
                    ForEach(subscriptionOptions, id: \.self) { product in
                        Button(action: {
                            print("Subscribe")
                            self.subscribe(product: product)
                        }) {
                            HStack {
                                if subscribeInProgress {
                                    ActivityIndicator(isAnimating: true)
                                }
                                VStack {
                                    Text("\(product.localizedTitle)")
                                    Text("\(getSubscriptionText(product)) per \(product.localizedSubscriptionPeriod), recurring")
                                }
                                
                            }
                        }
                        .buttonStyle(RoundedButtonStyle(backgroundColor: Color("AccentColor"), padded: false))
                        .padding(.horizontal)
                        .disabled(subscribeInProgress)
                    }
                    Button("Restore a subscription") {
                        print("Restore")
                        self.restoreSubscription()
                    }.padding(.vertical)
                    HStack {
                        Link(
                            "Privacy Policy",
                            destination: URL(string: "https://dark-maps.com/privacy-policy/")!)
                            .foregroundColor(.black)
                        Text("and")
                            .foregroundColor(.gray)
                        Link(
                            "Terms of Service",
                            destination: URL(string: "https://dark-maps.com/terms-of-service/")!)
                            .foregroundColor(.black)
                    }
                }
            } else {
                Text("Loading subscriptions...").font(.title2).padding(.top)
                ActivityIndicator(isAnimating: true).frame(width: 100, height: 100, alignment: .center)
            }
        }
        .padding()
        .onAppear(perform: {
            self.getSubscriptionOptions()
        })
        .onReceive(NotificationCenter.default.publisher(for: .subscriptionController_SubscriptionVerified), perform: {_ in
            withAnimation {
                appState.subscriptionSheetIsShowing = false
            }
        })
    }
}

struct SubscriptionSheet_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SubscriptionSheet()
                .preferredColorScheme(.dark)
            SubscriptionSheet(subscriptionOptions: [
                SKProduct(identifier: "Monthly Dark Maps Subscription", price: "0.99", priceLocale: .current, subscriptionPeriod: MockSKProductSubscriptionPeriod(numberOfUnits: 1, unit: .month))
            ])
            SubscriptionSheet(subscriptionOptions: [
                SKProduct(identifier: "Monthly Dark Maps Subscription", price: "0.99", priceLocale: .current, subscriptionPeriod: MockSKProductSubscriptionPeriod(numberOfUnits: 1, unit: .month)),
                SKProduct(identifier: "Yearly Dark Maps Subscription", price: "10", priceLocale: .current, subscriptionPeriod: MockSKProductSubscriptionPeriod(numberOfUnits: 1, unit: .year))
            ])
            SubscriptionSheet(subscriptionOptions: [
                SKProduct(identifier: "Monthly Dark Maps Subscription", price: "0.99", priceLocale: .current, subscriptionPeriod: MockSKProductSubscriptionPeriod(numberOfUnits: 1, unit: .month))
            ])
        }
    }
}


#if DEBUG

public extension SKProduct {
    convenience init(identifier: String, price: String, priceLocale: Locale, subscriptionPeriod: SKProductSubscriptionPeriod) {
        self.init()
        self.setValue(identifier, forKey: "localizedTitle")
        self.setValue(identifier, forKey: "productIdentifier")
        self.setValue(NSDecimalNumber(string: price), forKey: "price")
        self.setValue(priceLocale, forKey: "priceLocale")
        self.setValue(subscriptionPeriod, forKey: "subscriptionPeriod")
    }
}


class MockSKProductSubscriptionPeriod: SKProductSubscriptionPeriod {
    private let _numberOfUnits: Int
    private let _unit: SKProduct.PeriodUnit

    init(numberOfUnits: Int = 1, unit: SKProduct.PeriodUnit = .year) {
        _numberOfUnits = numberOfUnits
        _unit = unit
    }

    override var numberOfUnits: Int {
        self._numberOfUnits
    }

    override var unit: SKProduct.PeriodUnit {
        self._unit
    }
}

#endif
