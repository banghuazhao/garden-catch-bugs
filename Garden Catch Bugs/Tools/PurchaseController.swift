//
//  PurchaseController.swift
//  Garden Catch Bugs
//
//  Copyright © 2026 Banghua Zhao. All rights reserved.
//

import Foundation
import StoreKit

/// What came back from a purchase attempt.
enum PurchaseOutcome: Equatable {
    case purchased
    /// The shopper dismissed the sheet. Entitlement is unchanged.
    case cancelled
    /// Ask to Buy, or a payment awaiting action. Approval arrives later
    /// through `Transaction.updates`, not here.
    case pending
}

enum RestoreOutcome: Equatable {
    case restored
    case nothingToRestore
    case cancelled
}

enum PurchaseError: Error {
    /// The product could not be fetched from the App Store.
    case productUnavailable
    /// StoreKit could not vouch for the transaction's signature.
    case verificationFailed
    case failed
}

/// The app's view of purchasing, kept free of StoreKit types so tests can
/// substitute a fake and so server-side verification can be introduced later
/// without touching call sites.
@MainActor
protocol PurchaseControlling: AnyObject {
    /// The single source of truth for whether ads should appear anywhere.
    var isAdsRemoved: Bool { get }
    /// Store-localised price, or nil until the product has loaded.
    var removeAdsDisplayPrice: String? { get }

    func start()
    func loadProducts() async
    func buyRemoveAds() async throws -> PurchaseOutcome
    func restorePurchases() async throws -> RestoreOutcome
}

@MainActor
final class PurchaseController: PurchaseControlling {
    /// Mirrors the bundle ID with hyphens replaced by underscores: App Store
    /// Connect rejects hyphens in product IDs, so the bundle ID cannot be used
    /// verbatim.
    static let removeAdsProductID = "com.Banghua_Zhao.Garden_Catch_Bugs.remove_ads"
    static let shared = PurchaseController()

    private let entitlementStore: AdsEntitlementStoring
    private var updatesTask: Task<Void, Never>?
    private var removeAdsProduct: Product?

    init(entitlementStore: AdsEntitlementStoring = UserDefaultsAdsEntitlementStore()) {
        self.entitlementStore = entitlementStore
    }

    deinit {
        updatesTask?.cancel()
    }

    var isAdsRemoved: Bool { entitlementStore.isAdsRemoved }

    var removeAdsDisplayPrice: String? { removeAdsProduct?.displayPrice }

    func start() {
        guard updatesTask == nil else { return }
        // Deliberately never cancelled: this listener is how Ask to Buy
        // approvals, purchases made on another device, and refunds reach the
        // app. It has to outlive any one screen.
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                await self?.handle(update)
            }
        }
        Task { await refreshEntitlements() }
    }

    func loadProducts() async {
        do {
            let products = try await Product.products(for: [Self.removeAdsProductID])
            removeAdsProduct = products.first { $0.id == Self.removeAdsProductID }
        } catch {
            removeAdsProduct = nil
        }
    }

    func buyRemoveAds() async throws -> PurchaseOutcome {
        if removeAdsProduct == nil {
            await loadProducts()
        }
        guard let product = removeAdsProduct else {
            throw PurchaseError.productUnavailable
        }

        let result: Product.PurchaseResult
        do {
            result = try await product.purchase()
        } catch {
            throw PurchaseError.failed
        }

        switch result {
        case let .success(verification):
            guard case let .verified(transaction) = verification else {
                // An unverified transaction grants nothing.
                throw PurchaseError.verificationFailed
            }
            await refreshEntitlements()
            await transaction.finish()
            return .purchased
        case .userCancelled:
            return .cancelled
        case .pending:
            return .pending
        @unknown default:
            throw PurchaseError.failed
        }
    }

    func restorePurchases() async throws -> RestoreOutcome {
        do {
            try await AppStore.sync()
        } catch let error as StoreKitError {
            if case .userCancelled = error { return .cancelled }
            throw PurchaseError.failed
        } catch {
            throw PurchaseError.failed
        }
        await refreshEntitlements()
        return isAdsRemoved ? .restored : .nothingToRestore
    }

    /// Recomputes the entitlement from the App Store and reconciles the local
    /// cache in both directions — granting on a new purchase, revoking on a
    /// refund.
    func refreshEntitlements() async {
        var entitled = false
        for await result in Transaction.currentEntitlements {
            // `.unverified` is treated as no entitlement at all.
            guard case let .verified(transaction) = result else { continue }
            guard transaction.productID == Self.removeAdsProductID else { continue }
            guard transaction.revocationDate == nil else { continue }
            entitled = true
        }
        setAdsRemoved(entitled)
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        guard case let .verified(transaction) = result else { return }
        await refreshEntitlements()
        await transaction.finish()
    }

    private func setAdsRemoved(_ newValue: Bool) {
        guard entitlementStore.isAdsRemoved != newValue else { return }
        entitlementStore.isAdsRemoved = newValue
        NotificationCenter.default.post(name: .adsEntitlementDidChange, object: nil)
    }
}
