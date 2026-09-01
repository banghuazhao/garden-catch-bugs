//
//  AdsEntitlement.swift
//  Garden Catch Bugs
//
//  Copyright © 2026 Banghua Zhao. All rights reserved.
//

import Foundation

extension Notification.Name {
    /// Posted on the main thread whenever the ad-removal entitlement changes,
    /// in either direction. Ad entry points listen so a purchase (or a refund)
    /// takes effect without waiting for a relaunch.
    static let adsEntitlementDidChange = Notification.Name("adsEntitlementDidChange")
}

/// Local cache of the ad-removal entitlement.
///
/// The App Store is the authority. This exists only so a launch with no network
/// still knows whether to skip the ads SDK; `PurchaseController` reconciles it
/// against `Transaction.currentEntitlements` on every start and on every
/// `Transaction.updates` event, granting and revoking as needed.
///
/// Only a boolean is stored. Receipts, transaction identifiers and anything
/// else identifying the purchaser deliberately stay out of local storage.
protocol AdsEntitlementStoring: AnyObject {
    var isAdsRemoved: Bool { get set }
}

final class UserDefaultsAdsEntitlementStore: AdsEntitlementStoring {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var isAdsRemoved: Bool {
        get { defaults.bool(forKey: Constants.UserDefaultsKeys.ADS_REMOVED) }
        set { defaults.set(newValue, forKey: Constants.UserDefaultsKeys.ADS_REMOVED) }
    }
}
