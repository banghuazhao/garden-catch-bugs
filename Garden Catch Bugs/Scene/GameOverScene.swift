//
//  GameOverScene.swift
//  Garden Catch Bugs
//

#if !targetEnvironment(macCatalyst)
    import GoogleMobileAds
#endif
import Localize_Swift
import SpriteKit

private enum ResultsPalette {
    static let ink = SKColor(red: 0.06, green: 0.18, blue: 0.14, alpha: 1)
    static let forest = SKColor(red: 0.05, green: 0.28, blue: 0.20, alpha: 0.97)
    static let leaf = SKColor(red: 0.19, green: 0.61, blue: 0.32, alpha: 1)
    static let mint = SKColor(red: 0.73, green: 0.96, blue: 0.79, alpha: 1)
    static let cream = SKColor(red: 1.0, green: 0.97, blue: 0.84, alpha: 1)
    static let coral = SKColor(red: 0.92, green: 0.30, blue: 0.29, alpha: 1)
    static let amber = SKColor(red: 0.98, green: 0.76, blue: 0.24, alpha: 1)
}

final class GameOverScene: SKScene {
    /// Show an interstitial only once every few rounds so the results screen stays playable.
    private static let interstitialRoundInterval = 3

    /// Minimum time the results stay ad-free after the scene appears.
    private static let resultsRevealDuration: TimeInterval = 1.6

    var mode: GameMode = .classic
    var finalScore = 0
    var bestScore = 0
    var isNewBest = false

    private let presentedAt = Date()

    override func didMove(to view: SKView) {
        setGameBannerHidden(true)
        backgroundColor = ResultsPalette.ink
        buildResults()

        #if !targetEnvironment(macCatalyst)
            presentInterstitialIfDue(from: view)
        #else
            let moreAppsViewController = MoreAppsViewController()
            moreAppsViewController.modalPresentationStyle = .fullScreen
            view.window?.rootViewController?.present(moreAppsViewController, animated: true)
        #endif
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let button = namedButton(at: touch.location(in: self)) else { return }

        animateButtonPress(button)
        playSoundEffect(tapButtonSound)
        switch button.name {
        case "restartButton":
            // Replay lands back in the mode just played, which is what keeps a
            // survival run loop tight.
            let scene = GameScene(size: size, mode: mode)
            scene.scaleMode = .aspectFill
            view?.presentScene(scene, transition: .crossFade(withDuration: 0.26))
        case "backButton":
            let scene = MainMenuScene(size: size)
            scene.scaleMode = .aspectFill
            view?.presentScene(scene, transition: .crossFade(withDuration: 0.26))
        default:
            break
        }
    }
}

// MARK: - Layout

extension GameOverScene {
    private func buildResults() {
        let background = SKSpriteNode(imageNamed: "bg_2048x1536")
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        background.alpha = 0.92
        background.zPosition = 0
        addChild(background)

        let dimmer = SKShapeNode(rectOf: size)
        dimmer.position = CGPoint(x: size.width / 2, y: size.height / 2)
        dimmer.fillColor = SKColor.black.withAlphaComponent(0.38)
        dimmer.strokeColor = .clear
        dimmer.zPosition = 1
        addChild(dimmer)

        let panel = SKShapeNode(rectOf: CGSize(width: 780, height: 640), cornerRadius: 56)
        panel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 22)
        panel.fillColor = ResultsPalette.forest
        panel.strokeColor = ResultsPalette.mint.withAlphaComponent(0.72)
        panel.lineWidth = 5
        panel.zPosition = 2
        panel.setScale(0.74)
        addChild(panel)

        let trophy = SKShapeNode(circleOfRadius: 62)
        trophy.position = CGPoint(x: 0, y: 196)
        trophy.fillColor = ResultsPalette.leaf
        trophy.strokeColor = ResultsPalette.mint
        trophy.lineWidth = 4
        trophy.zPosition = 1
        panel.addChild(trophy)

        let modeLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        modeLabel.text = (mode == .survival ? "Survival" : "Classic").localized()
        modeLabel.fontColor = ResultsPalette.mint
        modeLabel.fontSize = 34
        modeLabel.verticalAlignmentMode = .center
        modeLabel.horizontalAlignmentMode = .center
        modeLabel.position = CGPoint(x: 0, y: 292)
        modeLabel.zPosition = 1
        panel.addChild(modeLabel)

        let trophyGlyph = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        trophyGlyph.text = "★"
        trophyGlyph.fontColor = ResultsPalette.cream
        trophyGlyph.fontSize = 74
        trophyGlyph.verticalAlignmentMode = .center
        trophyGlyph.horizontalAlignmentMode = .center
        trophyGlyph.position = .zero
        trophyGlyph.zPosition = 1
        trophy.addChild(trophyGlyph)

        let scoreCard = makeStatCard(
            title: "Score".localized(),
            value: "\(finalScore)",
            color: finalScore >= 0 ? ResultsPalette.leaf : ResultsPalette.coral,
            position: CGPoint(x: -196, y: 46))
        let bestCard = makeStatCard(
            title: "Best Score".localized(),
            value: "\(bestScore)",
            color: isNewBest ? ResultsPalette.amber : ResultsPalette.leaf,
            position: CGPoint(x: 196, y: 46))
        [scoreCard, bestCard].forEach { card in
            card.zPosition = 1
            panel.addChild(card)
        }

        if isNewBest {
            addNewBestBadge(to: bestCard)
        }

        for button in [
            makeButton(name: "restartButton", title: "Start".localized(), color: ResultsPalette.leaf, position: CGPoint(x: 0, y: -150)),
            makeButton(name: "backButton", title: "Back".localized(), color: ResultsPalette.ink, position: CGPoint(x: 0, y: -262)),
        ] {
            button.zPosition = 1
            panel.addChild(button)
        }

        panel.run(.sequence([
            .scale(to: 1.05, duration: 0.22),
            .scale(to: 1, duration: 0.16),
        ]), withKey: "enter")
        trophy.fillColor = isNewBest ? ResultsPalette.amber : ResultsPalette.leaf
        trophy.run(.repeatForever(.sequence([
            .scale(to: 1.08, duration: 0.85),
            .scale(to: 1, duration: 0.85),
        ])), withKey: "trophyPulse")
    }

    private func addNewBestBadge(to card: SKShapeNode) {
        let badge = SKShapeNode(rectOf: CGSize(width: 236, height: 54), cornerRadius: 27)
        // Offset right so the badge clears the trophy sitting in the gutter.
        badge.position = CGPoint(x: 42, y: 110)
        badge.fillColor = ResultsPalette.amber
        badge.strokeColor = ResultsPalette.cream.withAlphaComponent(0.8)
        badge.lineWidth = 3
        badge.zPosition = 1
        badge.setScale(0.01)
        card.addChild(badge)

        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = "New Best!".localized()
        label.fontColor = ResultsPalette.ink
        label.fontSize = 30
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = .zero
        label.zPosition = 1
        badge.addChild(label)

        badge.run(.sequence([
            .wait(forDuration: 0.34),
            .scale(to: 1.16, duration: 0.18),
            .scale(to: 1, duration: 0.12),
            .repeatForever(.sequence([
                .rotate(toAngle: 0.05, duration: 0.6),
                .rotate(toAngle: -0.05, duration: 0.6),
            ])),
        ]))
    }

    private func makeStatCard(title: String, value: String, color: SKColor, position: CGPoint) -> SKShapeNode {
        let card = SKShapeNode(rectOf: CGSize(width: 344, height: 172), cornerRadius: 30)
        card.position = position
        card.fillColor = SKColor.white.withAlphaComponent(0.12)
        card.strokeColor = color.withAlphaComponent(0.70)
        card.lineWidth = 3

        let titleLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        titleLabel.text = title
        titleLabel.fontColor = ResultsPalette.mint
        titleLabel.fontSize = 30
        titleLabel.verticalAlignmentMode = .center
        titleLabel.horizontalAlignmentMode = .center
        titleLabel.position = CGPoint(x: 0, y: 47)
        titleLabel.zPosition = 1
        card.addChild(titleLabel)

        let valueLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        valueLabel.text = value
        valueLabel.fontColor = ResultsPalette.cream
        valueLabel.fontSize = 72
        valueLabel.verticalAlignmentMode = .center
        valueLabel.horizontalAlignmentMode = .center
        valueLabel.position = CGPoint(x: 0, y: -26)
        valueLabel.zPosition = 1
        card.addChild(valueLabel)
        return card
    }

    private func makeButton(name: String, title: String, color: SKColor, position: CGPoint) -> SKShapeNode {
        let button = SKShapeNode(rectOf: CGSize(width: 390, height: 82), cornerRadius: 24)
        button.name = name
        button.position = position
        button.fillColor = color
        button.strokeColor = ResultsPalette.cream.withAlphaComponent(0.65)
        button.lineWidth = 3

        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = title
        label.fontColor = ResultsPalette.cream
        label.fontSize = 36
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = .zero
        label.zPosition = 1
        button.addChild(label)
        return button
    }
}

// MARK: - Input and ads

extension GameOverScene {
    private func namedButton(at location: CGPoint) -> SKNode? {
        for node in nodes(at: location) {
            var candidate: SKNode? = node
            while let current = candidate {
                if ["restartButton", "backButton"].contains(current.name ?? "") {
                    return current
                }
                candidate = current.parent
            }
        }
        return nil
    }

    private func animateButtonPress(_ button: SKNode) {
        button.removeAction(forKey: "press")
        button.run(.sequence([
            .scale(to: 0.92, duration: 0.05),
            .scale(to: 1, duration: 0.14),
        ]), withKey: "press")
    }

    #if !targetEnvironment(macCatalyst)
        private func presentInterstitialIfDue(from view: SKView) {
            guard adsAllowed else { return }
            let defaults = UserDefaults.standard
            let roundsSinceAd = defaults.integer(forKey: Constants.UserDefaultsKeys.ROUNDS_SINCE_AD) + 1
            guard roundsSinceAd >= Self.interstitialRoundInterval else {
                defaults.set(roundsSinceAd, forKey: Constants.UserDefaultsKeys.ROUNDS_SINCE_AD)
                return
            }
            defaults.set(0, forKey: Constants.UserDefaultsKeys.ROUNDS_SINCE_AD)

            GADInterstitialAd.load(withAdUnitID: Constants.interstitialAdID, request: GADRequest()) { [weak self] ad, error in
                if let error {
                    print("Failed to load interstitial ad with error: \(error.localizedDescription)")
                    return
                }
                guard let ad, let self, self.view === view else { return }
                // Let the player read the result before the ad takes over the screen.
                let elapsed = Date().timeIntervalSince(self.presentedAt)
                delay(seconds: max(0, Self.resultsRevealDuration - elapsed)) { [weak self] in
                    guard let self, self.view === view,
                          let rootViewController = view.window?.rootViewController,
                          rootViewController.presentedViewController == nil else { return }
                    ad.present(fromRootViewController: rootViewController)
                }
            }
        }
    #endif
}
