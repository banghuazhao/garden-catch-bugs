//
//  FakePurchaseController.swift
//  Garden Catch BugsTests
//

import Foundation
@testable import Garden_Catch_Bugs

/// Stands in for StoreKit so tests never touch the real store.
@MainActor
final class FakePurchaseController: PurchaseControlling {
    var isAdsRemoved: Bool = false
    var removeAdsDisplayPrice: String?

    var startCallCount = 0
    var loadProductsCallCount = 0

    /// What the next `buyRemoveAds()` should do.
    var purchaseResult: Result<PurchaseOutcome, Error> = .success(.purchased)
    /// What the next `restorePurchases()` should do.
    var restoreResult: Result<RestoreOutcome, Error> = .success(.restored)

    func start() { startCallCount += 1 }

    func loadProducts() async {
        loadProductsCallCount += 1
    }

    func buyRemoveAds() async throws -> PurchaseOutcome {
        let outcome = try purchaseResult.get()
        // Only a completed purchase grants anything; cancelled and pending do not.
        if case .purchased = outcome { isAdsRemoved = true }
        return outcome
    }

    func restorePurchases() async throws -> RestoreOutcome {
        let outcome = try restoreResult.get()
        if case .restored = outcome { isAdsRemoved = true }
        return outcome
    }

    /// Simulates a refund arriving through `Transaction.updates`.
    func simulateRevocation() { isAdsRemoved = false }
}

/// In-memory entitlement store for gating tests.
final class InMemoryEntitlementStore: AdsEntitlementStoring {
    var isAdsRemoved: Bool = false
}
