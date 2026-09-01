//
//  RemoveAdsTests.swift
//  Garden Catch BugsTests
//

import XCTest
@testable import Garden_Catch_Bugs

// MARK: - Entitlement persistence

final class AdsEntitlementStoreTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "RemoveAdsTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testDefaultsToNotPurchased() {
        let store = UserDefaultsAdsEntitlementStore(defaults: defaults)
        XCTAssertFalse(store.isAdsRemoved)
    }

    func testPersistsGrantAcrossInstances() {
        UserDefaultsAdsEntitlementStore(defaults: defaults).isAdsRemoved = true
        // A fresh instance stands in for the next cold launch, offline.
        XCTAssertTrue(UserDefaultsAdsEntitlementStore(defaults: defaults).isAdsRemoved)
    }

    func testPersistsRevocationAcrossInstances() {
        let store = UserDefaultsAdsEntitlementStore(defaults: defaults)
        store.isAdsRemoved = true
        store.isAdsRemoved = false
        XCTAssertFalse(UserDefaultsAdsEntitlementStore(defaults: defaults).isAdsRemoved)
    }
}

// MARK: - Ad gating

@MainActor
final class AdGatingTests: XCTestCase {
    func testAdsAllowedWhenNotPurchased() {
        let purchases = FakePurchaseController()
        purchases.isAdsRemoved = false
        XCTAssertTrue(areAdsAllowed(for: purchases))
    }

    func testAdsBlockedWhenPurchased() {
        let purchases = FakePurchaseController()
        purchases.isAdsRemoved = true
        XCTAssertFalse(areAdsAllowed(for: purchases))
    }

    func testAdsReturnAfterRevocation() {
        let purchases = FakePurchaseController()
        purchases.isAdsRemoved = true
        XCTAssertFalse(areAdsAllowed(for: purchases))

        purchases.simulateRevocation()
        XCTAssertTrue(areAdsAllowed(for: purchases), "A refund must put ads back.")
    }
}

// MARK: - Purchase state transitions

@MainActor
final class PurchaseFlowTests: XCTestCase {
    func testSuccessfulPurchaseGrantsEntitlement() async throws {
        let purchases = FakePurchaseController()
        let outcome = try await purchases.buyRemoveAds()

        XCTAssertEqual(outcome, .purchased)
        XCTAssertTrue(purchases.isAdsRemoved)
        XCTAssertFalse(areAdsAllowed(for: purchases))
    }

    func testCancelledPurchaseLeavesEntitlementUnchanged() async throws {
        let purchases = FakePurchaseController()
        purchases.purchaseResult = .success(.cancelled)

        let outcome = try await purchases.buyRemoveAds()

        XCTAssertEqual(outcome, .cancelled)
        XCTAssertFalse(purchases.isAdsRemoved)
        XCTAssertTrue(areAdsAllowed(for: purchases), "Cancelling must not remove ads.")
    }

    func testPendingPurchaseDoesNotGrantEntitlementYet() async throws {
        let purchases = FakePurchaseController()
        purchases.purchaseResult = .success(.pending)

        let outcome = try await purchases.buyRemoveAds()

        XCTAssertEqual(outcome, .pending)
        XCTAssertFalse(purchases.isAdsRemoved, "Ask to Buy grants nothing until approved.")
    }

    func testUnavailableProductThrowsAndLeavesAdsOn() async {
        let purchases = FakePurchaseController()
        purchases.purchaseResult = .failure(PurchaseError.productUnavailable)

        do {
            _ = try await purchases.buyRemoveAds()
            XCTFail("Expected productUnavailable to be thrown.")
        } catch PurchaseError.productUnavailable {
            XCTAssertFalse(purchases.isAdsRemoved)
            XCTAssertTrue(areAdsAllowed(for: purchases))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testVerificationFailureDoesNotGrantEntitlement() async {
        let purchases = FakePurchaseController()
        purchases.purchaseResult = .failure(PurchaseError.verificationFailed)

        _ = try? await purchases.buyRemoveAds()

        XCTAssertFalse(purchases.isAdsRemoved, "An unverified transaction must grant nothing.")
    }
}

// MARK: - Restore

@MainActor
final class RestoreTests: XCTestCase {
    func testRestoreWithPriorPurchaseGrantsEntitlement() async throws {
        let purchases = FakePurchaseController()
        let outcome = try await purchases.restorePurchases()

        XCTAssertEqual(outcome, .restored)
        XCTAssertTrue(purchases.isAdsRemoved)
    }

    func testRestoreWithNoPurchaseLeavesAdsOn() async throws {
        let purchases = FakePurchaseController()
        purchases.restoreResult = .success(.nothingToRestore)

        let outcome = try await purchases.restorePurchases()

        XCTAssertEqual(outcome, .nothingToRestore)
        XCTAssertFalse(purchases.isAdsRemoved)
        XCTAssertTrue(areAdsAllowed(for: purchases))
    }

    func testCancelledRestoreLeavesEntitlementUnchanged() async throws {
        let purchases = FakePurchaseController()
        purchases.isAdsRemoved = true
        purchases.restoreResult = .success(.cancelled)

        let outcome = try await purchases.restorePurchases()

        XCTAssertEqual(outcome, .cancelled)
        XCTAssertTrue(purchases.isAdsRemoved, "Cancelling a restore must not revoke.")
    }
}
