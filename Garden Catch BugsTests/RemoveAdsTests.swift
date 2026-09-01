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

// MARK: - Survival mode rules

final class SurvivalRunTests: XCTestCase {
    /// bee +3, ladyBug +2, leafBeetle +1 / blueBeetle -1, starBeetle -2, stinkBug -3
    private let friendly = BugKind.bee
    private let pest = BugKind.stinkBug

    func testStartsWithThreeLivesAndNoCombo() {
        let run = SurvivalRun()
        XCTAssertEqual(run.lives, 3)
        XCTAssertEqual(run.score, 0)
        XCTAssertEqual(run.multiplier, 1)
        XCTAssertFalse(run.isOver)
    }

    func testMultiplierStepsAtFiveTenAndFifteen() {
        var run = SurvivalRun()
        let steps: [(catches: Int, expected: Int)] = [(4, 1), (5, 2), (10, 3), (15, 4)]
        for step in steps {
            var fresh = SurvivalRun()
            for _ in 0 ..< step.catches { _ = fresh.capture(friendly) }
            XCTAssertEqual(fresh.multiplier, step.expected,
                           "\(step.catches) catches should give x\(step.expected)")
        }
        _ = run.capture(friendly)
        XCTAssertEqual(run.multiplier, 1)
    }

    func testMultiplierIsCappedAtFour() {
        var run = SurvivalRun()
        for _ in 0 ..< 40 { _ = run.capture(friendly) }
        XCTAssertEqual(run.multiplier, 4)
    }

    func testFriendlyCatchScoresAtCurrentMultiplier() {
        var run = SurvivalRun()
        // Fifth catch is the first at x2, so it is worth double.
        for _ in 0 ..< 4 { _ = run.capture(friendly) }
        let outcome = run.capture(friendly)
        XCTAssertEqual(outcome.pointsGained, friendly.points * 2)
        XCTAssertFalse(outcome.lostLife)
    }

    func testPestCostsALifeAndResetsCombo() {
        var run = SurvivalRun()
        for _ in 0 ..< 6 { _ = run.capture(friendly) }
        XCTAssertEqual(run.multiplier, 2)

        let outcome = run.capture(pest)

        XCTAssertTrue(outcome.lostLife)
        XCTAssertEqual(run.lives, 2)
        XCTAssertEqual(run.combo, 0)
        XCTAssertEqual(run.multiplier, 1, "A pest must drop the streak back to x1.")
    }

    func testRunEndsAfterThreePests() {
        var run = SurvivalRun()
        for _ in 0 ..< 2 { _ = run.capture(pest) }
        XCTAssertFalse(run.isOver)
        _ = run.capture(pest)
        XCTAssertTrue(run.isOver)
        XCTAssertEqual(run.lives, 0)
    }

    func testExtraLifeAwardedEveryHundredPoints() {
        var run = SurvivalRun()
        var awards = 0
        // Catch friendlies until well past the second threshold.
        while run.score < 210 {
            if run.capture(friendly).gainedExtraLife { awards += 1 }
        }
        XCTAssertEqual(awards, 2, "One extra life at 100 and another at 200.")
        XCTAssertEqual(run.lives, SurvivalRun.startingLives + 2)
    }

    func testExtraLifeIsNotAwardedTwiceForTheSameThreshold() {
        var run = SurvivalRun()
        while run.score < 100 { _ = run.capture(friendly) }
        let livesAfterFirstAward = run.lives
        _ = run.capture(friendly)
        XCTAssertEqual(run.lives, livesAfterFirstAward)
    }
}

// MARK: - Game modes

final class GameModeTests: XCTestCase {
    func testEachModeKeepsItsOwnBestScore() {
        XCTAssertNotEqual(GameMode.classic.bestScoreKey, GameMode.survival.bestScoreKey)
        XCTAssertEqual(GameMode.classic.bestScoreKey, Constants.UserDefaultsKeys.BEST_SCORE)
        XCTAssertEqual(GameMode.survival.bestScoreKey, Constants.UserDefaultsKeys.BEST_SCORE_SURVIVAL)
    }

    func testBugPoolsSplitFriendliesFromPests() {
        XCTAssertFalse(BugKind.friendlies.isEmpty)
        XCTAssertFalse(BugKind.pests.isEmpty)
        XCTAssertTrue(BugKind.friendlies.allSatisfy(\.isFriendly))
        XCTAssertTrue(BugKind.pests.allSatisfy { !$0.isFriendly })
        XCTAssertEqual(BugKind.friendlies.count + BugKind.pests.count, BugKind.allCases.count)
    }
}

// MARK: - Survival: escape pressure

final class SurvivalEscapeTests: XCTestCase {
    private let friendly = BugKind.bee
    private let pest = BugKind.stinkBug

    func testIdlePlayerCannotSurviveForever() {
        var run = SurvivalRun()
        var escapes = 0
        // A player who never touches the screen: every beneficial bug gets away.
        while !run.isOver {
            _ = run.missFriendly()
            escapes += 1
            XCTAssertLessThan(escapes, 100, "An idle run must end, not loop forever.")
        }
        XCTAssertTrue(run.isOver)
        XCTAssertEqual(run.score, 0)
        XCTAssertEqual(escapes, SurvivalRun.missesPerLife * SurvivalRun.startingLives)
    }

    func testEveryFifthEscapeCostsALife() {
        var run = SurvivalRun()
        for _ in 0 ..< (SurvivalRun.missesPerLife - 1) {
            XCTAssertFalse(run.missFriendly())
        }
        XCTAssertEqual(run.lives, SurvivalRun.startingLives)
        XCTAssertTrue(run.missFriendly())
        XCTAssertEqual(run.lives, SurvivalRun.startingLives - 1)
    }

    func testCatchingPaysBackAMiss() {
        var run = SurvivalRun()
        for _ in 0 ..< 4 { _ = run.missFriendly() }
        XCTAssertEqual(run.misses, 4)

        _ = run.capture(friendly)
        XCTAssertEqual(run.misses, 3, "A catch should pay back one miss.")

        // Still one short of the threshold, so no life is lost yet.
        XCTAssertFalse(run.missFriendly())
        XCTAssertEqual(run.lives, SurvivalRun.startingLives)
    }

    func testKeepingPaceNeverCostsALife() {
        var run = SurvivalRun()
        // Alternating a miss and a catch is a player holding even.
        for _ in 0 ..< 60 {
            _ = run.missFriendly()
            _ = run.capture(friendly)
        }
        XCTAssertEqual(run.lives, SurvivalRun.startingLives + (run.score / SurvivalRun.extraLifeInterval))
        XCTAssertFalse(run.isOver)
        XCTAssertLessThanOrEqual(run.misses, 1)
    }

    func testMissesDoNotBreakTheCombo() {
        var run = SurvivalRun()
        for _ in 0 ..< 6 { _ = run.capture(friendly) }
        XCTAssertEqual(run.multiplier, 2)

        _ = run.missFriendly()

        XCTAssertEqual(run.multiplier, 2, "An unreachable bug must not erase a clean streak.")
        XCTAssertEqual(run.combo, 6)
    }

    func testCatchingAPestStillBreaksTheCombo() {
        var run = SurvivalRun()
        for _ in 0 ..< 6 { _ = run.capture(friendly) }
        _ = run.capture(pest)
        XCTAssertEqual(run.combo, 0)
    }
}
