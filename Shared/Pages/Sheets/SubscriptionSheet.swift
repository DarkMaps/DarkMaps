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
    @Environment(\.colorScheme) var colorScheme
    
    @State var subscribeInProgress = false
    @State var subscriptionOptions: [SKProduct] = []
    
    let features: [String: String] = [
        "Live Messages": "Send messages for a specified period of time, even whilst Dark Maps is in the background.",
        "Support development": "Help us to keep the servers running and develop new features",
        "Security audit": "Help us to fund an audit of the Dark Maps app and server"
    ]
    
    func getSubscriptionOptions() {
        appState.subscriptionController.getSubscriptions() { result in
            switch result {
            case .success(let options):
                self.subscriptionOptions = options
            case .failure(let error):
                DispatchQueue.main.async {
                    appState.subscriptionSheetIsShowing = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        appState.displayedError = IdentifiableError(error)
                    }
                }
            }
        }
    }
    
    func subscribe(product: SKProduct) {
        subscribeInProgress = true
        appState.subscriptionController.purchaseSubscription(product: product) { result in
            subscribeInProgress = false
            switch result {
            case .success(let date):
                print(date)
            case .failure(let error):
                //Only display an error if the user cancelled the purchase themselves.
                if error != .purchaseCancelled {
                    DispatchQueue.main.async {
                        appState.subscriptionSheetIsShowing = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            appState.displayedError = IdentifiableError(error)
                        }
                    }
                }
            }
        }
    }
    
    func restoreSubscription() {
        subscribeInProgress = true
        appState.subscriptionController.restorePurchases() { result in
            DispatchQueue.main.async {
                subscribeInProgress = false
            }
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
        return "\(product.localizedPrice ?? product.price.description)  per \(product.localizedSubscriptionPeriod), recurring"
    }
    
    var body: some View {
        VStack {
            VStack {
                Text("Subscribe")
                    .font(.system(size: 30))
                    .foregroundColor(.accentColor)
                    .padding(.bottom, 2)
                Text("Subscribe to Dark Maps to access the benefits below. Cancel any time you wish from the settings menu.").padding(.horizontal)
            }
            Spacer()
            TabView {
                ForEach(features.sorted(by: <), id: \.key) { title, description in
                    ZStack {
                        Color("AccentColor")
                        VStack {
                            Text("\(title)")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                            Rectangle()
                                .fill(Color.white)
                                .frame(maxWidth: .infinity, maxHeight: 2)
                            Text("\(description)").foregroundColor(.white)
                        }.padding(.horizontal)
                        .padding(.bottom, 25)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 10.0, style: .continuous))
                }
                .padding(.horizontal, 10)
            }
            .frame(width: UIScreen.main.bounds.width, height: 160)
            .tabViewStyle(PageTabViewStyle())
            Spacer()
            if subscriptionOptions.count > 0 {
                VStack {
                    ForEach(subscriptionOptions, id: \.self) { product in
                        Button(action: {
                            print("Subscribe")
                            self.subscribe(product: product)
                        }) {
                            VStack {
                                
                                HStack {
                                    if subscribeInProgress {
                                        ActivityIndicator(isAnimating: true)
                                    }
                                    Text("\(product.localizedTitle.count == 0 ? "Subscribe" : product.localizedTitle )")
//
                                }
                                
                                Text(getSubscriptionText(product))
                                
                            }
                        }
                        .buttonStyle(RoundedButtonStyle(backgroundColor: Color("AccentColor"), padded: false))
                        .padding(.horizontal, UIScreen.main.bounds.width / 40)
                        .padding(.top)
                        .disabled(subscribeInProgress)
                    }
                    Button("Restore a subscription") {
                        print("Restore")
                        self.restoreSubscription()
                    }.padding(.bottom, 1)
                    HStack {
                        Link(
                            "Privacy Policy",
                            destination: URL(string: "https://dark-maps.net/privacy-policy/")!)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        Text("and")
                            .foregroundColor(.gray)
                        Link(
                            "Terms of Service",
                            destination: URL(string: "https://dark-maps.net/terms-of-service/")!)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }.padding(.bottom, 2)
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

#if DEBUG

struct SubscriptionSheet_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SubscriptionSheet()
                .environmentObject(AppState())
                .preferredColorScheme(.dark)
            SubscriptionSheet(subscriptionOptions: [
                SKProduct(identifier: "Monthly Dark Maps Subscription", price: "0.99", priceLocale: .current, subscriptionPeriod: MockSKProductSubscriptionPeriod(numberOfUnits: 1, unit: .month))
            ])
            .environmentObject(AppState())
            SubscriptionSheet(subscriptionOptions: [
                SKProduct(identifier: "Monthly Dark Maps Subscription", price: "0.99", priceLocale: .current, subscriptionPeriod: MockSKProductSubscriptionPeriod(numberOfUnits: 1, unit: .month)),
                SKProduct(identifier: "Yearly Dark Maps Subscription", price: "10", priceLocale: .current, subscriptionPeriod: MockSKProductSubscriptionPeriod(numberOfUnits: 1, unit: .year))
            ])
            .environmentObject(AppState())
            SubscriptionSheet(subscriptionOptions: [
                SKProduct(identifier: "Monthly Dark Maps Subscription", price: "0.99", priceLocale: .current, subscriptionPeriod: MockSKProductSubscriptionPeriod(numberOfUnits: 1, unit: .month))
            ])
            .environmentObject(AppState())
            SubscriptionSheet(subscriptionOptions: [
                SKProduct(identifier: "Monthly Dark Maps Subscription", price: "0.99", priceLocale: .current, subscriptionPeriod: MockSKProductSubscriptionPeriod(numberOfUnits: 1, unit: .month))
            ])
            .environmentObject(AppState())
            .preferredColorScheme(.dark)
            SubscriptionSheet(subscriptionOptions: [
                SKProduct(identifier: "Monthly Dark Maps Subscription", price: "0.99", priceLocale: .current, subscriptionPeriod: MockSKProductSubscriptionPeriod(numberOfUnits: 1, unit: .month))
            ])
            .previewDevice("iPod touch (7th generation)")
            .environmentObject(AppState())
            .preferredColorScheme(.dark)
        }
    }
}

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
