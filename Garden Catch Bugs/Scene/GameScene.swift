//
//  GameScene.swift
//  Garden Catch Bugs
//

import Localize_Swift
import SpriteKit
import UIKit

private enum GameState {
    case playing
    case paused
}

/// The two ways to play. Classic is the original fixed 60-second round;
/// Survival drops the clock and gates the run on lives instead, so a skilled
/// player keeps going and each run has its own high score to beat.
enum GameMode {
    case classic
    case survival

    var bestScoreKey: String {
        switch self {
        case .classic: return Constants.UserDefaultsKeys.BEST_SCORE
        case .survival: return Constants.UserDefaultsKeys.BEST_SCORE_SURVIVAL
        }
    }
}

enum BugKind: String, CaseIterable {
    case bee
    case ladyBug = "lady_bug"
    case leafBeetle = "leafbeetle"
    case blueBeetle = "blue_beetle"
    case starBeetle = "starbeetle"
    case stinkBug = "stinkbug"

    var textureName: String {
        switch self {
        case .bee: return "bee_1"
        case .ladyBug: return "lady_bug_1"
        case .leafBeetle: return "leafbeetle_1"
        case .blueBeetle: return "blue_beetle_1"
        case .starBeetle: return "starbeetle_1"
        case .stinkBug: return "stinkbug_1"
        }
    }

    var animation: SKAction {
        switch self {
        case .bee: return beeAnimation
        case .ladyBug: return ladyBugAnimation
        case .leafBeetle: return leafBeetleAnimation
        case .blueBeetle: return blueBeetleAnimation
        case .starBeetle: return starBeetleAnimation
        case .stinkBug: return stinkBugAnimation
        }
    }

    var points: Int {
        switch self {
        case .bee: return 3
        case .ladyBug: return 2
        case .leafBeetle: return 1
        case .blueBeetle: return -1
        case .starBeetle: return -2
        case .stinkBug: return -3
        }
    }

    var isFriendly: Bool { points > 0 }

    static var friendlies: [BugKind] { allCases.filter(\.isFriendly) }
    static var pests: [BugKind] { allCases.filter { !$0.isFriendly } }

    var feedbackColor: SKColor {
        isFriendly
            ? SKColor(red: 0.24, green: 0.79, blue: 0.40, alpha: 1)
            : SKColor(red: 0.94, green: 0.29, blue: 0.32, alpha: 1)
    }
}

private enum GardenPalette {
    static let ink = SKColor(red: 0.06, green: 0.18, blue: 0.14, alpha: 1)
    static let forest = SKColor(red: 0.05, green: 0.28, blue: 0.20, alpha: 0.92)
    /// Opaque variant for modal panels, so live gameplay can't read through them.
    static let forestSolid = SKColor(red: 0.04, green: 0.22, blue: 0.16, alpha: 1)
    static let leaf = SKColor(red: 0.19, green: 0.61, blue: 0.32, alpha: 1)
    static let mint = SKColor(red: 0.73, green: 0.96, blue: 0.79, alpha: 1)
    static let cream = SKColor(red: 1.0, green: 0.97, blue: 0.84, alpha: 1)
    static let coral = SKColor(red: 0.92, green: 0.30, blue: 0.29, alpha: 1)
    static let amber = SKColor(red: 0.98, green: 0.76, blue: 0.24, alpha: 1)
}

final class GameScene: SKScene {
    private let catchBadBugSound = SKAction.playSoundFileNamed("抓到害虫.mp3", waitForCompletion: false)
    private let catchGoodBugSound = SKAction.playSoundFileNamed("抓到益虫.mp3", waitForCompletion: false)
    private let tapSound = SKAction.playSoundFileNamed("按键.mp3", waitForCompletion: false)

    private var gameState: GameState = .playing
    private var playableRect = CGRect.zero
    private var topLimit: CGFloat = 0
    private var bottomLimit: CGFloat = 0
    private var lastSlicePoint: CGPoint?
    private var notificationObservers = [NSObjectProtocol]()
    private var gameEnded = false
    private var lastUpdateTime: TimeInterval = 0
    private var createWave = Array(repeating: true, count: 5)
    private var isTimerUrgent = false

    private let playfieldNode = SKNode()
    private let gameLayerNode = SKNode()
    private let effectsNode = SKNode()
    private let hudNode = SKNode()
    private var pauseOverlay: SKNode?
    private var timeBarFill: SKShapeNode?

    /// Rendered size of a bug sprite, fixed so spawn margins can be trusted.
    fileprivate static let bugScale: CGFloat = 0.6

    private let mode: GameMode
    private var startingBest = 0

    /// Survival state. Unused in Classic.
    private var run = SurvivalRun()
    private var lives = SurvivalRun.startingLives {
        didSet { updateLivesUI() }
    }

    private var survivalStage = 0
    private var elapsed: TimeInterval = 0

    private let maxTime: TimeInterval = 60
    private var timeRemaining: TimeInterval = 60 {
        didSet { updateTimerUI() }
    }

    private var score = 0 {
        didSet { updateScoreUI() }
    }

    private lazy var netNode: SKSpriteNode = {
        let node = SKSpriteNode(imageNamed: "net")
        node.zPosition = 4
        node.setScale(0.3)
        return node
    }()

    private let scoreLabel = GameScene.makeHUDLabel(alignment: .center)
    private let bestScoreLabel = GameScene.makeHUDLabel(alignment: .center)
    /// Right-hand HUD slot: the clock in Classic, remaining lives in Survival.
    private let timeLabel = GameScene.makeHUDLabel(alignment: .center)
    private let comboLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private var timeBarTrack: SKShapeNode?

    init(size: CGSize, mode: GameMode = .classic) {
        self.mode = mode
        super.init(size: size)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        addObservers()
        setGameBannerHidden(true)
        backgroundColor = GardenPalette.ink
        gameState = .playing
        startingBest = UserDefaults.standard.object(forKey: mode.bestScoreKey) as? Int ?? 0
        playBackgroundMusic(filename: "游戏音乐.mp3", repeatForever: true)
        createWorld()
        createHUD()
        startSpawningBugs()
    }

    override func willMove(from view: SKView) {
        notificationObservers.forEach(NotificationCenter.default.removeObserver)
        notificationObservers.removeAll()
    }

    override func update(_ currentTime: TimeInterval) {
        guard gameState == .playing, !gameEnded else { return }

        let deltaTime = lastUpdateTime > 0 ? currentTime - lastUpdateTime : 0
        lastUpdateTime = currentTime
        elapsed += deltaTime

        switch mode {
        case .classic:
            timeRemaining -= deltaTime
            if timeRemaining <= 0 {
                endRound()
                return
            }
            for (index, waveTime) in [50, 40, 30, 20, 10].enumerated() {
                if timeRemaining <= TimeInterval(waveTime), createWave[index] {
                    createWave[index] = false
                    spawnBugWave()
                }
            }
        case .survival:
            advanceSurvivalStage()
        }
    }

    /// Survival ramps in 20-second steps: bugs come faster, fly faster, and the
    /// mix tilts towards pests. Each step opens with a wave so the change is felt.
    private func advanceSurvivalStage() {
        let stage = Int(elapsed / 20)
        guard stage > survivalStage else { return }
        survivalStage = stage
        restartSpawners()
        spawnBugWave()
        showToast(String(format: "Wave %d".localized(), stage + 1), color: GardenPalette.mint)
    }
}

// MARK: - Input

extension GameScene {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        if handleControlTap(at: location) { return }
        guard gameState == .playing, !gameEnded else { return }

        lastSlicePoint = location
        showNet(at: location)
        captureBugs(at: location)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, gameState == .playing, !gameEnded else { return }
        let location = touch.location(in: self)
        let previousLocation = lastSlicePoint
        lastSlicePoint = location

        showNet(at: location)
        if let previousLocation {
            addSwipeTrail(from: previousLocation, to: location)
        }
        captureBugs(at: location)
    }

    override func touchesEnded(_ touches: Set<UITouch>?, with event: UIEvent?) {
        hideNet()
        lastSlicePoint = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }

    private func handleControlTap(at location: CGPoint) -> Bool {
        guard let control = namedControl(at: location) else { return false }

        switch control.name {
        case "pauseButton":
            animateButtonPress(control)
            playSoundEffect(tapSound)
            pauseGame()
        case "resumeButton":
            animateButtonPress(control)
            playSoundEffect(tapSound)
            resumeGame()
        case "backButton":
            animateButtonPress(control)
            playSoundEffect(tapSound)
            returnToMainMenu()
        default:
            return false
        }
        return true
    }

    private func namedControl(at location: CGPoint) -> SKNode? {
        for node in nodes(at: location) {
            var candidate: SKNode? = node
            while let current = candidate {
                if ["pauseButton", "resumeButton", "backButton"].contains(current.name ?? "") {
                    return current
                }
                candidate = current.parent
            }
        }
        return nil
    }
}

// MARK: - Game feel

extension GameScene {
    private func showNet(at location: CGPoint) {
        netNode.position = location
        if netNode.parent == nil {
            effectsNode.addChild(netNode)
        }
        netNode.removeAction(forKey: "netPop")
        netNode.setScale(0.28)
        netNode.run(.sequence([
            .scale(to: 0.34, duration: 0.06),
            .scale(to: 0.30, duration: 0.10),
        ]), withKey: "netPop")
    }

    private func hideNet() {
        netNode.removeFromParent()
    }

    private func addSwipeTrail(from start: CGPoint, to end: CGPoint) {
        let path = CGMutablePath()
        path.move(to: start)
        path.addLine(to: end)

        let trail = SKShapeNode(path: path)
        trail.strokeColor = GardenPalette.mint.withAlphaComponent(0.72)
        trail.lineWidth = 14
        trail.lineCap = .round
        trail.zPosition = 1
        effectsNode.addChild(trail)
        trail.run(.sequence([
            .group([
                .fadeOut(withDuration: 0.18),
                .scale(to: 0.92, duration: 0.18),
            ]),
            .removeFromParent(),
        ]))
    }

    private func captureBugs(at location: CGPoint) {
        for node in nodes(at: location) {
            guard let name = node.name,
                  let kind = BugKind(rawValue: name),
                  node.action(forKey: "capture") == nil else { continue }
            capture(node, as: kind)
        }
    }

    private func capture(_ bug: SKNode, as kind: BugKind) {
        bug.name = nil
        bug.removeAllActions()

        var gained = kind.points
        var outcome: SurvivalRun.Outcome?
        if mode == .survival {
            let result = run.capture(kind)
            gained = result.pointsGained
            outcome = result
            updateComboUI()
        }
        score += gained

        let position = bug.position
        addCaptureBurst(at: position, kind: kind)
        addScorePop(at: position, points: gained, color: kind.feedbackColor)
        shakePlayfield(intensity: kind.isFriendly ? 9 : 14)
        hitStop(duration: kind.isFriendly ? 0.04 : 0.09)
        triggerHaptic(isFriendly: kind.isFriendly)
        playSoundEffect(kind.isFriendly ? catchGoodBugSound : catchBadBugSound)

        if let outcome {
            if outcome.gainedExtraLife {
                showToast("Extra Life!".localized(), color: GardenPalette.leaf)
            }
            if outcome.lostLife { flashDanger() }
            lives = run.lives
            if run.isOver { endRound() }
        }

        let squash = SKAction.scale(to: 0.88, duration: 0.05)
        let exit = SKAction.group([
            .scale(to: 0.06, duration: 0.22),
            .fadeOut(withDuration: 0.22),
            .rotate(byAngle: kind.isFriendly ? .pi * 1.5 : -.pi * 1.5, duration: 0.22),
        ])
        bug.run(.sequence([squash, exit, .removeFromParent()]), withKey: "capture")
    }

    private func addCaptureBurst(at position: CGPoint, kind: BugKind) {
        let colors = [kind.feedbackColor, GardenPalette.cream, GardenPalette.mint]
        for index in 0 ..< 11 {
            let sparkle = SKShapeNode(circleOfRadius: index.isMultiple(of: 3) ? 10 : 6)
            sparkle.fillColor = colors[index % colors.count]
            sparkle.strokeColor = .clear
            sparkle.position = position
            sparkle.zPosition = 2
            effectsNode.addChild(sparkle)

            let angle = CGFloat(index) / 11 * .pi * 2 + CGFloat.random(in: -0.18 ... 0.18)
            let distance = CGFloat.random(in: 66 ... 132)
            let destination = CGPoint(
                x: position.x + cos(angle) * distance,
                y: position.y + sin(angle) * distance)
            sparkle.run(.sequence([
                .group([
                    .move(to: destination, duration: 0.32),
                    .rotate(byAngle: .pi * 2, duration: 0.32),
                    .sequence([
                        .wait(forDuration: 0.12),
                        .fadeOut(withDuration: 0.20),
                    ]),
                ]),
                .removeFromParent(),
            ]))
        }
    }

    private func addScorePop(at position: CGPoint, points: Int, color: SKColor) {
        let scorePop = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        scorePop.text = points > 0 ? "+\(points)" : "\(points)"
        scorePop.fontColor = color
        scorePop.fontSize = 52
        scorePop.horizontalAlignmentMode = .center
        scorePop.verticalAlignmentMode = .center
        scorePop.position = position
        scorePop.zPosition = 3
        scorePop.setScale(0.55)
        effectsNode.addChild(scorePop)
        scorePop.run(.sequence([
            .group([
                .moveBy(x: 0, y: 108, duration: 0.55),
                .sequence([
                    .scale(to: 1.18, duration: 0.12),
                    .scale(to: 0.96, duration: 0.16),
                ]),
                .sequence([
                    .wait(forDuration: 0.28),
                    .fadeOut(withDuration: 0.27),
                ]),
            ]),
            .removeFromParent(),
        ]))
    }

    /// A red vignette pulse, so losing a life reads instantly without a modal.
    private func flashDanger() {
        let flash = SKShapeNode(rectOf: size)
        flash.position = CGPoint(x: size.width / 2, y: size.height / 2)
        flash.fillColor = GardenPalette.coral.withAlphaComponent(0.34)
        flash.strokeColor = .clear
        flash.zPosition = 5
        effectsNode.addChild(flash)
        flash.run(.sequence([.fadeOut(withDuration: 0.32), .removeFromParent()]))
        shakePlayfield(intensity: 18)
    }

    private func showToast(_ text: String, color: SKColor) {
        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = text
        label.fontColor = color
        label.fontSize = 82
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: size.width / 2, y: size.height / 2 + 120)
        label.zPosition = 6
        label.setScale(0.6)
        effectsNode.addChild(label)
        label.run(.sequence([
            .group([.scale(to: 1.08, duration: 0.18), .fadeIn(withDuration: 0.14)]),
            .scale(to: 1, duration: 0.12),
            .wait(forDuration: 0.5),
            .group([.moveBy(x: 0, y: 60, duration: 0.3), .fadeOut(withDuration: 0.3)]),
            .removeFromParent(),
        ]))
    }

    /// Freezes the playfield for a couple of frames so a catch lands with weight.
    /// Effects keep animating, which is what sells the impact.
    private func hitStop(duration: TimeInterval) {
        guard gameState == .playing, !gameEnded else { return }
        gameLayerNode.speed = 0
        removeAction(forKey: "hitStop")
        run(.sequence([
            .wait(forDuration: duration),
            .run { [weak self] in self?.gameLayerNode.speed = 1 },
        ]), withKey: "hitStop")
    }

    private func shakePlayfield(intensity: CGFloat) {
        guard playfieldNode.action(forKey: "shake") == nil else { return }
        let moves: [SKAction] = [
            .moveBy(x: intensity, y: -intensity * 0.45, duration: 0.025),
            .moveBy(x: -intensity * 1.45, y: intensity * 0.8, duration: 0.04),
            .moveBy(x: intensity * 0.75, y: -intensity * 0.42, duration: 0.04),
            .move(to: .zero, duration: 0.06),
        ]
        playfieldNode.run(.sequence(moves), withKey: "shake")
    }

    private func triggerHaptic(isFriendly: Bool) {
        #if !targetEnvironment(macCatalyst)
            let generator = UIImpactFeedbackGenerator(style: isFriendly ? .medium : .rigid)
            generator.prepare()
            generator.impactOccurred(intensity: isFriendly ? 0.72 : 0.9)
        #endif
    }
}

// MARK: - Scene construction

extension GameScene {
    private func createWorld() {
        playfieldNode.zPosition = 0
        addChild(playfieldNode)

        let background = SKSpriteNode(imageNamed: "bg_2048x1536")
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        background.zPosition = 0
        playfieldNode.addChild(background)

        gameLayerNode.zPosition = 1
        playfieldNode.addChild(gameLayerNode)

        effectsNode.zPosition = 10
        addChild(effectsNode)

        let playableMargin = sceneCropAmount() / 2
        playableRect = CGRect(
            x: 0,
            y: playableMargin,
            width: size.width,
            height: size.height - playableMargin * 2)
        topLimit = playableRect.maxY - 164
        bottomLimit = playableRect.minY
    }

    private func createHUD() {
        hudNode.zPosition = 100
        addChild(hudNode)
        let hudY = playableRect.maxY - 78

        let strip = SKShapeNode(rectOf: CGSize(width: size.width - 64, height: 122), cornerRadius: 34)
        strip.position = CGPoint(x: size.width / 2, y: hudY)
        strip.fillColor = GardenPalette.forest
        strip.strokeColor = GardenPalette.mint.withAlphaComponent(0.35)
        strip.lineWidth = 3
        strip.zPosition = 0
        hudNode.addChild(strip)

        let scoreCard = makeHUDCard(center: CGPoint(x: 218, y: hudY), size: CGSize(width: 326, height: 88))
        let bestCard = makeHUDCard(center: CGPoint(x: size.width / 2, y: hudY), size: CGSize(width: 400, height: 88))
        let timeCard = makeHUDCard(center: CGPoint(x: size.width - 292, y: hudY), size: CGSize(width: 270, height: 88))
        [scoreCard, bestCard, timeCard].forEach { card in
            card.zPosition = 1
            hudNode.addChild(card)
        }

        scoreLabel.position = CGPoint(x: scoreCard.position.x, y: scoreCard.position.y + 9)
        bestScoreLabel.position = CGPoint(x: bestCard.position.x, y: bestCard.position.y + 9)
        timeLabel.position = CGPoint(x: timeCard.position.x, y: timeCard.position.y + 16)
        [scoreLabel, bestScoreLabel, timeLabel].forEach { label in
            label.zPosition = 2
            hudNode.addChild(label)
        }

        let barTrack = SKShapeNode(rectOf: CGSize(width: 194, height: 10), cornerRadius: 5)
        barTrack.position = CGPoint(x: timeCard.position.x, y: timeCard.position.y - 24)
        barTrack.fillColor = SKColor.black.withAlphaComponent(0.22)
        barTrack.strokeColor = .clear
        barTrack.zPosition = 2
        barTrack.isHidden = mode == .survival
        hudNode.addChild(barTrack)
        timeBarTrack = barTrack

        let fill = SKShapeNode(rectOf: CGSize(width: 188, height: 6), cornerRadius: 3)
        fill.position = barTrack.position
        fill.fillColor = GardenPalette.leaf
        fill.strokeColor = .clear
        fill.zPosition = 3
        fill.isHidden = mode == .survival
        hudNode.addChild(fill)
        timeBarFill = fill

        comboLabel.fontColor = GardenPalette.amber
        comboLabel.fontSize = 38
        comboLabel.horizontalAlignmentMode = .center
        comboLabel.verticalAlignmentMode = .center
        comboLabel.position = CGPoint(x: scoreCard.position.x, y: scoreCard.position.y - 26)
        comboLabel.zPosition = 3
        comboLabel.alpha = 0
        hudNode.addChild(comboLabel)

        let pauseButton = SKShapeNode(circleOfRadius: 44)
        pauseButton.position = CGPoint(x: size.width - 78, y: hudY)
        pauseButton.name = "pauseButton"
        pauseButton.fillColor = GardenPalette.leaf
        pauseButton.strokeColor = GardenPalette.mint
        pauseButton.lineWidth = 3
        pauseButton.zPosition = 4
        hudNode.addChild(pauseButton)

        let pauseGlyph = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        pauseGlyph.text = "Ⅱ"
        pauseGlyph.fontColor = GardenPalette.cream
        pauseGlyph.fontSize = 36
        pauseGlyph.verticalAlignmentMode = .center
        pauseGlyph.horizontalAlignmentMode = .center
        pauseGlyph.position = .zero
        pauseGlyph.zPosition = 1
        pauseButton.addChild(pauseGlyph)

        updateScoreUI()
        switch mode {
        case .classic: updateTimerUI()
        case .survival: updateLivesUI()
        }
    }

    private func makeHUDCard(center: CGPoint, size: CGSize) -> SKShapeNode {
        let card = SKShapeNode(rectOf: size, cornerRadius: 24)
        card.position = center
        card.fillColor = SKColor.white.withAlphaComponent(0.13)
        card.strokeColor = SKColor.white.withAlphaComponent(0.16)
        card.lineWidth = 2
        return card
    }

    private static func makeHUDLabel(alignment: SKLabelHorizontalAlignmentMode) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.fontColor = GardenPalette.cream
        label.fontSize = 41
        label.horizontalAlignmentMode = alignment
        label.verticalAlignmentMode = .center
        return label
    }

    private func updateScoreUI() {
        scoreLabel.text = "\("Score".localized()): \(score)"

        let storedBest = UserDefaults.standard.object(forKey: mode.bestScoreKey) as? Int ?? 0
        let bestScore = max(storedBest, score)
        if bestScore != storedBest {
            UserDefaults.standard.set(bestScore, forKey: mode.bestScoreKey)
        }
        bestScoreLabel.text = "\("Best Score".localized()): \(bestScore)"

        guard scoreLabel.parent != nil else { return }
        scoreLabel.removeAction(forKey: "scorePulse")
        scoreLabel.setScale(1)
        scoreLabel.run(.sequence([
            .scale(to: 1.18, duration: 0.08),
            .scale(to: 1, duration: 0.18),
        ]), withKey: "scorePulse")
    }

    private func updateLivesUI() {
        guard mode == .survival else { return }
        timeLabel.text = String(repeating: "♥", count: max(0, lives))
        timeLabel.fontColor = lives <= 1 ? GardenPalette.coral : GardenPalette.cream
        guard timeLabel.parent != nil else { return }
        timeLabel.removeAction(forKey: "livesPulse")
        timeLabel.setScale(1)
        timeLabel.run(.sequence([
            .scale(to: 1.22, duration: 0.09),
            .scale(to: 1, duration: 0.18),
        ]), withKey: "livesPulse")
    }

    private func updateComboUI() {
        guard mode == .survival else { return }
        let multiplier = run.multiplier
        guard multiplier > 1 else {
            comboLabel.run(.fadeOut(withDuration: 0.18))
            return
        }
        comboLabel.text = String(format: "Combo x%d".localized(), multiplier)
        comboLabel.alpha = 1
        comboLabel.removeAction(forKey: "comboPop")
        comboLabel.setScale(1)
        comboLabel.run(.sequence([
            .scale(to: 1.28, duration: 0.08),
            .scale(to: 1, duration: 0.16),
        ]), withKey: "comboPop")
    }

    private func updateTimerUI() {
        guard mode == .classic else { return }
        let roundedTime = max(0, Int(ceil(timeRemaining)))
        timeLabel.text = "\("Time".localized()): \(roundedTime)s"
        timeBarFill?.xScale = max(0.02, CGFloat(timeRemaining / maxTime))

        if timeRemaining <= 10 {
            timeLabel.fontColor = GardenPalette.coral
            timeBarFill?.fillColor = GardenPalette.coral
            if !isTimerUrgent {
                isTimerUrgent = true
                timeLabel.run(.repeatForever(.sequence([
                    .scale(to: 1.1, duration: 0.34),
                    .scale(to: 1, duration: 0.34),
                ])), withKey: "urgentTimer")
            }
        } else {
            timeLabel.fontColor = GardenPalette.cream
            timeBarFill?.fillColor = GardenPalette.leaf
        }
    }

    private func sceneCropAmount() -> CGFloat {
        guard let view else { return 0 }
        let scale = max(view.bounds.width / size.width, view.bounds.height / size.height)
        let scaledHeight = size.height * scale
        return max(0, scaledHeight - view.bounds.height) / scale
    }
}

// MARK: - Bug spawning

/// The edge a bug enters from. Every bug crosses the playfield and exits the far side.
private enum SpawnEdge: CaseIterable {
    case top, bottom, left, right
}

extension GameScene {
    /// Bug sprites are drawn head-up, so a bug travelling along `vector` has to be
    /// rotated from that resting orientation onto its heading.
    private static func heading(for vector: CGVector) -> CGFloat {
        atan2(vector.dy, vector.dx) - .pi / 2
    }

    private func startSpawningBugs() {
        for (index, edge) in SpawnEdge.allCases.enumerated() {
            let action = SKAction.sequence([
                .wait(forDuration: 0.5 + Double(index) * 0.22),
                .repeatForever(.sequence([
                    .run { [weak self] in self?.spawnBug(from: edge) },
                    .wait(forDuration: spawnInterval, withRange: 0.5),
                ])),
            ])
            gameLayerNode.run(action, withKey: "spawner\(index)")
        }
    }

    /// Spawner waits are baked into a running action, so a rate change means
    /// rebuilding them.
    private func restartSpawners() {
        for index in SpawnEdge.allCases.indices {
            gameLayerNode.removeAction(forKey: "spawner\(index)")
        }
        startSpawningBugs()
    }

    private var spawnInterval: TimeInterval {
        switch mode {
        case .classic: return 1.35
        case .survival: return max(0.5, 1.25 - Double(survivalStage) * 0.13)
        }
    }

    /// Survival opens forgiving and tightens: pests climb from about a third of
    /// spawns to nearly two thirds.
    private func randomKind() -> BugKind {
        switch mode {
        case .classic:
            return BugKind.allCases.randomElement() ?? .bee
        case .survival:
            let pestChance = min(0.6, 0.35 + Double(survivalStage) * 0.04)
            let pool = Double.random(in: 0 ..< 1) < pestChance ? BugKind.pests : BugKind.friendlies
            return pool.randomElement() ?? .bee
        }
    }

    private func makeBug() -> SKSpriteNode {
        let kind = randomKind()
        let bug = SKSpriteNode(imageNamed: kind.textureName)
        bug.name = kind.rawValue
        bug.zPosition = 2
        bug.setScale(GameScene.bugScale)
        bug.run(.repeatForever(kind.animation), withKey: "flutter")
        // A small wing-tilt wobble around the heading, which always returns to zero.
        bug.run(.repeatForever(.sequence([
            .rotate(byAngle: 0.07, duration: 0.42),
            .rotate(byAngle: -0.14, duration: 0.84),
            .rotate(byAngle: 0.07, duration: 0.42),
        ])), withKey: "wobble")
        return bug
    }

    private func spawnBug(from edge: SpawnEdge) {
        let bug = makeBug()
        // Half the diagonal, so the sprite is clear of the screen at any heading.
        let radius = hypot(bug.size.width, bug.size.height) / 2
        let laneX = { CGFloat.random(in: radius ... max(radius, self.size.width - radius)) }
        let laneY = { CGFloat.random(in: self.bottomLimit + radius ... max(self.bottomLimit + radius, self.topLimit - radius)) }

        let origin: CGPoint
        let destination: CGPoint
        switch edge {
        case .top:
            origin = CGPoint(x: laneX(), y: playableRect.maxY + radius)
            destination = CGPoint(x: laneX(), y: playableRect.minY - radius)
        case .bottom:
            origin = CGPoint(x: laneX(), y: playableRect.minY - radius)
            destination = CGPoint(x: laneX(), y: playableRect.maxY + radius)
        case .left:
            origin = CGPoint(x: -radius, y: laneY())
            destination = CGPoint(x: size.width + radius, y: laneY())
        case .right:
            origin = CGPoint(x: size.width + radius, y: laneY())
            destination = CGPoint(x: -radius, y: laneY())
        }

        bug.position = origin
        gameLayerNode.addChild(bug)
        fly(bug, to: destination)
    }

    private func fly(_ bug: SKSpriteNode, to destination: CGPoint) {
        let vector = CGVector(dx: destination.x - bug.position.x, dy: destination.y - bug.position.y)
        bug.zRotation = GameScene.heading(for: vector)

        let distance = hypot(vector.dx, vector.dy)
        let speed = CGFloat.random(in: 300 ... 430) * difficultyMultiplier
        bug.run(.sequence([
            .move(to: destination, duration: TimeInterval(distance / speed)),
            .removeFromParent(),
        ]), withKey: "travel")
    }

    /// Bugs speed up gently as the round runs down.
    private var difficultyMultiplier: CGFloat {
        switch mode {
        case .classic:
            let progress = CGFloat(1 - max(0, timeRemaining) / maxTime)
            return 1 + progress * 0.45
        case .survival:
            return min(2.1, 1 + CGFloat(survivalStage) * 0.13)
        }
    }

    private func spawnBugWave() {
        shakePlayfield(intensity: 5)
        let edges = SpawnEdge.allCases
        for index in 0 ..< 10 {
            let edge = edges[index % edges.count]
            gameLayerNode.run(.sequence([
                .wait(forDuration: Double(index) * 0.09),
                .run { [weak self] in self?.spawnBug(from: edge) },
            ]))
        }
    }
}

// MARK: - Pause and completion

extension GameScene {
    private func pauseGame() {
        guard gameState == .playing, !gameEnded else { return }
        gameState = .paused
        removeAction(forKey: "hitStop")
        gameLayerNode.speed = 1
        setWorldFrozen(true)
        hideNet()
        lastSlicePoint = nil
        pauseBackgroundMusic()

        let overlay = SKNode()
        overlay.name = "pauseOverlay"
        overlay.zPosition = 200
        addChild(overlay)
        pauseOverlay = overlay

        let dimmer = SKShapeNode(rectOf: size)
        dimmer.position = CGPoint(x: size.width / 2, y: size.height / 2)
        dimmer.fillColor = SKColor.black.withAlphaComponent(0.52)
        dimmer.strokeColor = .clear
        dimmer.zPosition = 0
        overlay.addChild(dimmer)

        let panel = SKShapeNode(rectOf: CGSize(width: 600, height: 430), cornerRadius: 48)
        panel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        panel.fillColor = GardenPalette.forestSolid
        panel.strokeColor = GardenPalette.mint.withAlphaComponent(0.7)
        panel.lineWidth = 5
        panel.zPosition = 1
        panel.setScale(0.78)
        overlay.addChild(panel)

        let pauseGlyph = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        pauseGlyph.text = "Ⅱ"
        pauseGlyph.fontColor = GardenPalette.mint
        pauseGlyph.fontSize = 112
        pauseGlyph.verticalAlignmentMode = .center
        pauseGlyph.horizontalAlignmentMode = .center
        pauseGlyph.position = CGPoint(x: 0, y: 126)
        pauseGlyph.zPosition = 1
        panel.addChild(pauseGlyph)

        let pauseTitle = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        pauseTitle.text = "Pause".localized()
        pauseTitle.fontColor = GardenPalette.cream
        pauseTitle.fontSize = 46
        pauseTitle.verticalAlignmentMode = .center
        pauseTitle.horizontalAlignmentMode = .center
        pauseTitle.position = CGPoint(x: 0, y: 48)
        pauseTitle.zPosition = 1
        panel.addChild(pauseTitle)

        for button in [
            makeMenuButton(name: "resumeButton", title: "Resume".localized(), color: GardenPalette.leaf, position: CGPoint(x: 0, y: -32)),
            makeMenuButton(name: "backButton", title: "Back".localized(), color: GardenPalette.coral, position: CGPoint(x: 0, y: -154)),
        ] {
            button.zPosition = 1
            panel.addChild(button)
        }
        panel.run(.sequence([
            .scale(to: 1.04, duration: 0.17),
            .scale(to: 1, duration: 0.13),
        ]), withKey: "enter")
    }

    /// Freezes everything that belongs to the round — bugs, spawners, screen shake
    /// and lingering effects — while leaving the HUD and the pause panel live.
    private func setWorldFrozen(_ frozen: Bool) {
        playfieldNode.isPaused = frozen
        gameLayerNode.isPaused = frozen
        effectsNode.isPaused = frozen
        physicsWorld.speed = frozen ? 0 : 1
    }

    private func resumeGame() {
        guard gameState == .paused else { return }
        gameState = .playing
        gameLayerNode.speed = 1
        setWorldFrozen(false)
        lastUpdateTime = 0
        resumeBackgroundMusic()

        let overlay = pauseOverlay
        pauseOverlay = nil
        overlay?.run(.sequence([
            .group([
                .fadeOut(withDuration: 0.16),
                .scale(to: 1.04, duration: 0.16),
            ]),
            .removeFromParent(),
        ]))
    }

    private func returnToMainMenu() {
        setWorldFrozen(false)
        endBackgroundMusic()
        let scene = MainMenuScene(size: size)
        scene.scaleMode = .aspectFill
        view?.presentScene(scene, transition: .crossFade(withDuration: 0.28))
    }

    private func endRound() {
        guard !gameEnded else { return }
        gameEnded = true
        gameState = .paused
        setWorldFrozen(true)
        endBackgroundMusic()

        let scene = GameOverScene(size: size)
        scene.mode = mode
        scene.finalScore = score
        scene.bestScore = max(startingBest, score)
        scene.isNewBest = score > startingBest
        scene.scaleMode = .aspectFill
        view?.presentScene(scene, transition: .crossFade(withDuration: 0.35))
    }

    private func makeMenuButton(name: String, title: String, color: SKColor, position: CGPoint) -> SKShapeNode {
        let button = SKShapeNode(rectOf: CGSize(width: 390, height: 84), cornerRadius: 24)
        button.name = name
        button.position = position
        button.fillColor = color
        button.strokeColor = GardenPalette.cream.withAlphaComponent(0.68)
        button.lineWidth = 3

        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = title
        label.fontColor = GardenPalette.cream
        label.fontSize = 36
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = .zero
        label.zPosition = 1
        button.addChild(label)
        return button
    }

    private func animateButtonPress(_ button: SKNode) {
        button.removeAction(forKey: "press")
        button.run(.sequence([
            .scale(to: 0.92, duration: 0.05),
            .scale(to: 1, duration: 0.14),
        ]), withKey: "press")
    }
}

// MARK: - Application lifecycle

extension GameScene {
    private func addObservers() {
        let notificationCenter = NotificationCenter.default
        notificationObservers.append(notificationCenter.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.pauseGame()
        })
        notificationObservers.append(notificationCenter.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.pauseGame()
        })
        // SpriteKit un-pauses the scene for us when the app returns to the
        // foreground, which would set the bugs moving again underneath the pause
        // panel. Re-assert the freeze whenever the round is still paused.
        notificationObservers.append(notificationCenter.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self, self.gameState == .paused else { return }
            self.setWorldFrozen(true)
        })
    }
}
