//
//  SurvivalRun.swift
//  Garden Catch Bugs
//
//  Copyright © 2026 Banghua Zhao. All rights reserved.
//

import Foundation

/// Scoring and lives for a Survival run, kept free of SpriteKit so the mode's
/// balance is testable on its own.
///
/// Survival removes Classic's 60-second ceiling: a run lasts as long as the
/// player keeps pests off the net, so skill translates directly into session
/// length. The combo multiplier rewards a clean streak, and an extra life every
/// 100 points keeps a good run alive just past the point it would have ended.
struct SurvivalRun {
    static let startingLives = 3
    static let extraLifeInterval = 100

    private(set) var score = 0
    private(set) var lives = SurvivalRun.startingLives
    private(set) var combo = 0
    private var nextExtraLifeAt = SurvivalRun.extraLifeInterval

    /// x1 below a 5-catch streak, then x2, x3 and x4. Any pest resets it, which
    /// is what makes a long clean streak worth protecting.
    var multiplier: Int {
        switch combo {
        case 15...: return 4
        case 10 ..< 15: return 3
        case 5 ..< 10: return 2
        default: return 1
        }
    }

    var isOver: Bool { lives <= 0 }

    struct Outcome: Equatable {
        var pointsGained: Int
        var lostLife: Bool
        var gainedExtraLife: Bool
    }

    mutating func capture(_ kind: BugKind) -> Outcome {
        var gainedExtraLife = false
        let gained: Int

        if kind.isFriendly {
            combo += 1
            gained = kind.points * multiplier
        } else {
            combo = 0
            // A pest still stings the score as well as costing a life.
            gained = kind.points
        }
        score += gained

        if score >= nextExtraLifeAt {
            nextExtraLifeAt += Self.extraLifeInterval
            lives += 1
            gainedExtraLife = true
        }
        if !kind.isFriendly {
            lives -= 1
        }

        return Outcome(pointsGained: gained, lostLife: !kind.isFriendly, gainedExtraLife: gainedExtraLife)
    }
}
