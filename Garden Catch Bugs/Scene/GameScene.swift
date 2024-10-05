//
//  GameScene.swift
//  Garden Catch Bugs
//
//  Created by Banghua Zhao on 5/24/20.
//  Copyright © 2020 Banghua Zhao. All rights reserved.
//

import Localize_Swift
import SpriteKit
import Then

enum GameState {
    case play, pause
}

class GameScene: SKScene {
    var gameState: GameState = .play

    // music
    let catchBadBugSound: SKAction = SKAction.playSoundFileNamed(
        "抓到害虫.mp3", waitForCompletion: false)
    let catchGoodBugSound: SKAction = SKAction.playSoundFileNamed(
        "抓到益虫.mp3", waitForCompletion: false)
    let tapSound = SKAction.playSoundFileNamed("按键.mp3", waitForCompletion: true)

    // playble rect
    var playableRect: CGRect!
    var topLimit: CGFloat!
    var bottomLimit: CGFloat!

    // Touch
    var activeSlicePoints = [CGPoint]()

    // character

    var gameLayerNode = SKNode()

    lazy var netNode = SKSpriteNode(imageNamed: "net").then({ node in
        node.zPosition = 98
        node.setScale(0.3)
    })

    // score

    var score: Int = 0 {
        didSet {
            if score > newbestScore {
                newbestScore = score
            }
            scoreLabel.text = "\("Score".localized()): \(score)"
            if let bestScore = UserDefaults.standard.value(forKey: Constants.UserDefaultsKeys.BEST_SCORE) as? Int {
                if score > bestScore {
                    bestScoreLabel.text = "\("Best Score".localized()): \(score)"
                    UserDefaults.standard.set(score, forKey: Constants.UserDefaultsKeys.BEST_SCORE)
                }
            } else {
                bestScoreLabel.text = "\("Best Score".localized()): \(score)"
                UserDefaults.standard.set(score, forKey: Constants.UserDefaultsKeys.BEST_SCORE)
            }
        }
    }

    var newbestScore: Int = 0

    lazy var scoreLabel = SKLabelNode(fontNamed: "Helvetica-Bold").then { node in
        node.text = "\("Score".localized()): 0"
        node.fontColor = SKColor.black
        node.fontSize = 54
        node.zPosition = 100
        node.horizontalAlignmentMode = .left
        node.verticalAlignmentMode = .top
    }

    lazy var bestScoreLabel = SKLabelNode(fontNamed: "Helvetica-Bold").then { node in
        if let bestScore = UserDefaults.standard.value(forKey: Constants.UserDefaultsKeys.BEST_SCORE) as? Int {
            node.text = "\("Best Score".localized()): \(bestScore)"
        } else {
            UserDefaults.standard.set(0, forKey: Constants.UserDefaultsKeys.BEST_SCORE)
            node.text = "\("Best Score".localized()): 0"
        }
        node.fontColor = SKColor.black
        node.fontSize = 54
        node.zPosition = 100
        node.horizontalAlignmentMode = .center
        node.verticalAlignmentMode = .top
    }

    // Time

    var isResume = false
    var gameEnded = false
    var lastUpdateTime: TimeInterval = 0.0
    var dt: TimeInterval = 0.0

    var maxTime: TimeInterval = 60.0

    var timeRemind: TimeInterval = 60.0 {
        didSet {
            timeLabel.text = "\("Time".localized()): \(String(format: "%.1f", timeRemind)) / \(maxTime)"
        }
    }

    lazy var timeLabel = SKLabelNode(fontNamed: "Helvetica-Bold").then { node in
        node.text = "\("Time".localized()): \(String(format: "%.1f", timeRemind)) / \(maxTime)"
        node.fontColor = SKColor.black
        node.fontSize = 54
        node.zPosition = 100
        node.horizontalAlignmentMode = .right
        node.verticalAlignmentMode = .top
    }

    var createWave: [Bool] = [true, true, true, true, true]

    // MARK: - didMove

    override func didMove(to view: SKView) {
        addObservers()
        #if !targetEnvironment(macCatalyst)
            bannerView.isHidden = true
        #endif
        gameState = .play
        playBackgroundMusic(filename: "游戏音乐.mp3", repeatForever: true)

        createWorld()
        createLabels()
        spawnBugs1()
    }

    // MARK: - update

    override func update(_ currentTime: TimeInterval) {
        if gameState == .pause {
            if !gameLayerNode.isPaused {
                physicsWorld.speed = 0
                gameLayerNode.isPaused = true
                gameState = .pause
                print("paused!")
                let pauseMenu = SKSpriteNode(imageNamed: "pauseMenu")
                pauseMenu.zPosition = 200
                pauseMenu.position = CGPoint(
                    x: size.width / 2,
                    y: (bottomLimit + topLimit) / 2 + 50)
                pauseMenu.name = "pauseMenu"
                addChild(pauseMenu)

                let resumeButton = SKSpriteNode(imageNamed: "button")
                resumeButton.position = CGPoint(
                    x: 0, y: 0)
                resumeButton.zPosition = 2
                resumeButton.name = "resumeButton"
                pauseMenu.addChild(resumeButton)

                let resumeLabel = SKLabelNode(fontNamed: "Helvetica-Bold").then { node in
                    node.text = "Resume".localized()
                    node.fontColor = SKColor.black
                    node.fontSize = 50
                    node.zPosition = 100
                    node.horizontalAlignmentMode = .center
                    node.verticalAlignmentMode = .center
                    node.position = CGPoint(x: 0, y: 0)
                }

                resumeButton.addChild(resumeLabel)

                let backButton = SKSpriteNode(imageNamed: "button")
                backButton.position = CGPoint(
                    x: 0, y: -180)
                backButton.zPosition = 2
                backButton.name = "backButton"
                pauseMenu.addChild(backButton)

                let backLabel = SKLabelNode(fontNamed: "Helvetica-Bold").then { node in
                    node.text = "Back".localized()
                    node.fontColor = SKColor.black
                    node.fontSize = 50
                    node.zPosition = 100
                    node.horizontalAlignmentMode = .center
                    node.verticalAlignmentMode = .center
                    node.position = CGPoint(x: 0, y: 0)
                }
                backButton.addChild(backLabel)
            }
            return
        }

        if isResume {
            lastUpdateTime = currentTime
            isResume = false
        }

        // Called before each frame is rendered
        dt = lastUpdateTime > 0 ? currentTime - lastUpdateTime : 0
        timeRemind -= dt
        lastUpdateTime = currentTime

        if timeRemind <= 0.0 {
            timeUp()
        }

        // spawn wave

        for (i, waveTime) in [10, 20, 30, 40, 50].enumerated() {
            if timeRemind <= TimeInterval(waveTime) && createWave[i] {
                createWave[i] = false
                spawnBugWave()
            }
        }
    }
}

// MARK: - touch related

extension GameScene {
    // MARK: - touchesBegan

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        activeSlicePoints.removeAll(keepingCapacity: true)

        guard let vTouch = touches.first else { return }
        let touchLocation = vTouch.location(in: self)
        activeSlicePoints.append(touchLocation)

        let nodesAtPoint = nodes(at: touchLocation)

        for node in nodesAtPoint {
            if node.name == "pauseButton" {
                if !gameLayerNode.isPaused {
                    physicsWorld.speed = 0
                    gameLayerNode.isPaused = true
                    gameState = .pause
                    run(tapSound)
                    print("paused!")
                    let pauseMenu = SKSpriteNode(imageNamed: "pauseMenu")
                    pauseMenu.zPosition = 200
                    pauseMenu.position = CGPoint(
                        x: size.width / 2,
                        y: (bottomLimit + topLimit) / 2 + 50)
                    pauseMenu.name = "pauseMenu"
                    addChild(pauseMenu)

                    let resumeButton = SKSpriteNode(imageNamed: "button")
                    resumeButton.position = CGPoint(
                        x: 0, y: 0)
                    resumeButton.zPosition = 2
                    resumeButton.name = "resumeButton"
                    pauseMenu.addChild(resumeButton)

                    let resumeLabel = SKLabelNode(fontNamed: "Helvetica-Bold").then { node in
                        node.text = "Resume".localized()
                        node.fontColor = SKColor.black
                        node.fontSize = 50
                        node.zPosition = 100
                        node.horizontalAlignmentMode = .center
                        node.verticalAlignmentMode = .center
                        node.position = CGPoint(x: 0, y: 0)
                    }

                    resumeButton.addChild(resumeLabel)

                    let backButton = SKSpriteNode(imageNamed: "button")
                    backButton.position = CGPoint(
                        x: 0, y: -180)
                    backButton.zPosition = 2
                    backButton.name = "backButton"
                    pauseMenu.addChild(backButton)

                    let backLabel = SKLabelNode(fontNamed: "Helvetica-Bold").then { node in
                        node.text = "Back".localized()
                        node.fontColor = SKColor.black
                        node.fontSize = 50
                        node.zPosition = 100
                        node.horizontalAlignmentMode = .center
                        node.verticalAlignmentMode = .center
                        node.position = CGPoint(x: 0, y: 0)
                    }
                    backButton.addChild(backLabel)
                }
                #if !targetEnvironment(macCatalyst)
                    bannerView.isHidden = false
                #endif
            } else if node.name == "resumeButton" {
                run(tapSound)
                enumerateChildNodes(withName: "pauseMenu") { node, _ in
                    node.removeFromParent()
                }
                isResume = true
                gameLayerNode.isPaused = false
                physicsWorld.speed = 1
                gameState = .play
                #if !targetEnvironment(macCatalyst)
                    bannerView.isHidden = true
                #endif
                return
            } else if node.name == "backButton" {
                isResume = true
                gameLayerNode.isPaused = false
                backgroundMusicPlayer.stop()
                run(tapSound)
                let mainMenuScene = MainMenuScene()
                mainMenuScene.size = size
                mainMenuScene.scaleMode = .aspectFill
                view?.presentScene(mainMenuScene)
            }
        }

        if !gameLayerNode.isPaused {
            netNode.position = touchLocation
            if netNode.parent == nil {
                addChild(netNode)
            }
        }
    }

    // MARK: - touchesMoved

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !gameEnded else { return }

        guard let vTouch = touches.first else { return }
        let touchLocation = vTouch.location(in: self)
        activeSlicePoints.append(touchLocation)

        netNode.position = touchLocation

        let nodesAtPoint = nodes(at: touchLocation)

        for node in nodesAtPoint {
            switch node.name {
            case "bee":
                score += 3
                node.name = ""
                node.run(catchAnimation())
                run(catchGoodBugSound)
            case "lady_bug":
                score += 2
                node.name = ""
                node.run(catchAnimation())
                run(catchGoodBugSound)
            case "leafbeetle":
                score += 1
                node.name = ""
                node.run(catchAnimation())
                run(catchGoodBugSound)
            case "blue_beetle":
                score -= 1
                node.name = ""
                node.run(catchAnimation())
                run(catchBadBugSound)
            case "starbeetle":
                score -= 2
                node.name = ""
                node.run(catchAnimation())
                run(catchBadBugSound)
            case "stinkbug":
                score -= 3
                node.name = ""
                node.run(catchAnimation())
                run(catchBadBugSound)
            default:
                break
            }
        }
    }

    func catchAnimation() -> SKAction {
        let scaleOutAction = SKAction.scale(by: 0.001, duration: 0.6)
        let fadeOutAction = SKAction.fadeOut(withDuration: 0.6)
        let rotateAction = SKAction.rotate(byAngle: CGFloat(2 * Double.pi), duration: 0.6)
        let action = SKAction.sequence([
            SKAction.group([scaleOutAction, fadeOutAction, rotateAction]),
            SKAction.removeFromParent(),
        ])
        return action
    }

    // MARK: - touchesEnded

    override func touchesEnded(_ touches: Set<UITouch>?, with event: UIEvent?) {
        if !gameLayerNode.isPaused {
            netNode.removeFromParent()
        }
    }

    // MARK: - touchesCancelled

    override func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?) {
        guard let vTouches = touches else { return }
        touchesEnded(vTouches, with: event)
    }
}

// MARK: - helper

extension GameScene {
    func sceneCropAmount() -> CGFloat {
        guard let view = view else { return 0 }

        let scale = view.bounds.size.width / size.width
        print("scale: \(scale)")
        let scaledHeight = size.height * scale
        let scaledOverlap = scaledHeight - view.bounds.size.height
        return scaledOverlap / scale
    }

    // MARK: - createWorld

    func createWorld() {
        addChild(gameLayerNode)
        let background = SKSpriteNode(imageNamed: "bg_2048x1536")
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        background.zPosition = 1
        addChild(background)

        let playableMargin = sceneCropAmount() / 2.0
        #if !targetEnvironment(macCatalyst)
            let playableHeight = size.height - 2 * playableMargin
        #else
            let playableHeight = size.height - 2 * playableMargin - 50
        #endif
        playableRect = CGRect(x: 0, y: playableMargin,
                              width: size.width,
                              height: playableHeight)

        let toolbar = SKSpriteNode(imageNamed: "toolbar")
        toolbar.position = CGPoint(
            x: size.width / 2,
            y: playableRect.minY + playableRect.height - toolbar.size.height / 2)
        toolbar.zPosition = 99
        addChild(toolbar)

        let pauseButton = SKSpriteNode(imageNamed: "pauseButton")
        pauseButton.setScale(0.6)
        pauseButton.position = CGPoint(
            x: size.width - 180,
            y: playableRect.minY + playableRect.height - 60)
        pauseButton.zPosition = 100
        pauseButton.name = "pauseButton"
        addChild(pauseButton)

        topLimit = playableRect.minY + playableRect.height - toolbar.size.height

        bottomLimit = playableRect.minY
    }

    // MARK: - createLabels

    func createLabels() {
//        #if !targetEnvironment(macCatalyst)
        let labelY = topLimit + 100
//        #else
//            let labelY = topLimit + 0
//        #endif

        scoreLabel.position = CGPoint(
            x: 80,
            y: labelY)

        bestScoreLabel.position = CGPoint(
            x: size.width / 2 - 180,
            y: labelY)

        timeLabel.position = CGPoint(
            x: size.width - CGFloat(320),
            y: labelY)

        addChild(scoreLabel)
        addChild(bestScoreLabel)
        addChild(timeLabel)
    }

    // MARK: - spawnBugs1

    func spawnBugs1() {
        delay(seconds: 1.0) {
            self.gameLayerNode.run(
                SKAction.repeatForever(
                    SKAction.sequence([
                        SKAction.run(self.createTopBugs),
                        SKAction.wait(forDuration: 1.5, withRange: 0.5),
                    ]))
            )
        }

        delay(seconds: 1.0) {
            self.gameLayerNode.run(
                SKAction.repeatForever(
                    SKAction.sequence([
                        SKAction.run(self.createLeftBugs),
                        SKAction.wait(forDuration: 1.5, withRange: 0.5),
                    ]))
            )
        }

        delay(seconds: 1.0) {
            self.gameLayerNode.run(
                SKAction.repeatForever(
                    SKAction.sequence([
                        SKAction.run(self.createRightBugs),
                        SKAction.wait(forDuration: 1.5, withRange: 0.5),
                    ]))
            )
        }

        delay(seconds: 1.0) {
            self.gameLayerNode.run(
                SKAction.repeatForever(
                    SKAction.sequence([
                        SKAction.run(self.createBottomBugs),
                        SKAction.wait(forDuration: 1.5, withRange: 0.5),
                    ]))
            )
        }
    }
}

// MARK: - create bug related

extension GameScene {
    // MARK: - bug related

    func createRandomBug() -> SKSpriteNode {
        var bug: SKSpriteNode!
        var bugAnimation: SKAction!
        let kind = lround(Double(random(min: 0.0, max: 5.0)))
        switch kind {
        case 0:
            bug = SKSpriteNode(imageNamed: "bee_1")
            bug.name = "bee"
            bugAnimation = beeAnimation
        case 1:
            bug = SKSpriteNode(imageNamed: "lady_bug_1")
            bug.name = "lady_bug"
            bugAnimation = ladyBugAnimation
        case 2:
            bug = SKSpriteNode(imageNamed: "leafbeetle_1")
            bug.name = "leafbeetle"
            bugAnimation = leafBeetleAnimation
        case 3:
            bug = SKSpriteNode(imageNamed: "blue_beetle_1")
            bug.name = "blue_beetle"
            bugAnimation = blueBeetleAnimation
        case 4:
            bug = SKSpriteNode(imageNamed: "starbeetle_1")
            bug.name = "starbeetle"
            bugAnimation = starBeetleAnimation
        case 5:
            bug = SKSpriteNode(imageNamed: "stinkbug_1")
            bug.name = "stinkbug"
            bugAnimation = stinkBugAnimation
        default:
            bug = SKSpriteNode(imageNamed: "bee_1")
            bug.name = "bee"
            bugAnimation = beeAnimation
        }
        bug.setScale(0.6)
        bug.zPosition = 2
        bug.run(SKAction.repeatForever(bugAnimation))
        return bug
    }

    func createTopBugs() {
        let bug = createRandomBug()
        let initialX = CGFloat.random(
            min: 0 + bug.size.width / 2,
            max: size.width - bug.size.width / 2)
        let initialY = CGFloat(topLimit) + bug.size.height / 2

        bug.position = CGPoint(
            x: initialX,
            y: initialY)
        bug.zRotation = CGFloat.pi
        gameLayerNode.addChild(bug)

        let offsetX = random(min: size.width * 1 / 4, max: size.width)
        let deltaX = random(min: -offsetX, max: offsetX)
        let deltaY = bottomLimit - topLimit - bug.size.height / 2
        bug.zRotation -= atan(deltaX / deltaY)
        let duration = TimeInterval(random(
            min: random(min: 3, max: 4),
            max: random(min: 5, max: 6)))
        let actionMove =
            SKAction.moveBy(x: deltaX, y: deltaY, duration: duration)
        let actionRemove = SKAction.removeFromParent()
        bug.run(SKAction.sequence([actionMove, actionRemove]))
    }

    func createLeftBugs() {
        let bug = createRandomBug()
        let initialX: CGFloat = CGFloat(0) - bug.size.width / 2
        let initialY: CGFloat = CGFloat.random(
            min: bottomLimit + bug.size.height / 2,
            max: topLimit - bug.size.height / 2)

        bug.position = CGPoint(
            x: initialX,
            y: initialY)
        bug.zRotation = -CGFloat.pi / 2
        gameLayerNode.addChild(bug)

        let deltaX: CGFloat = size.width + bug.size.width / 2
        let offsetX = random(min: size.height * 1 / 4, max: size.height)
        let deltaY: CGFloat = random(min: -offsetX, max: offsetX)
        bug.zRotation += atan(deltaY / deltaX)
        let duration = TimeInterval(random(
            min: random(min: 3, max: 4),
            max: random(min: 5, max: 6)))
        let actionMove =
            SKAction.moveBy(x: deltaX, y: deltaY, duration: duration)
        let actionRemove = SKAction.removeFromParent()
        bug.run(SKAction.sequence([actionMove, actionRemove]))
    }

    func createRightBugs() {
        let bug = createRandomBug()
        let initialX: CGFloat = CGFloat(size.width) + bug.size.width / 2
        let initialY: CGFloat = CGFloat.random(
            min: bottomLimit + bug.size.height / 2,
            max: topLimit - bug.size.height / 2)

        bug.position = CGPoint(
            x: initialX,
            y: initialY)
        bug.zRotation = CGFloat.pi / 2
        gameLayerNode.addChild(bug)

        let deltaX: CGFloat = -size.width - bug.size.width / 2
        let offsetX = random(min: size.height * 1 / 4, max: size.height)
        let deltaY: CGFloat = random(min: -offsetX, max: offsetX)
        bug.zRotation += atan(deltaY / deltaX)
        let duration = TimeInterval(random(
            min: random(min: 3, max: 4),
            max: random(min: 5, max: 6)))
        let actionMove =
            SKAction.moveBy(x: deltaX, y: deltaY, duration: duration)
        let actionRemove = SKAction.removeFromParent()
        bug.run(SKAction.sequence([actionMove, actionRemove]))
    }

    func createBottomBugs() {
        let bug = createRandomBug()
        let initialX = CGFloat.random(
            min: 0 + bug.size.width / 2,
            max: size.width - bug.size.width / 2)
        let initialY = CGFloat(bottomLimit) - bug.size.height / 2

        bug.position = CGPoint(
            x: initialX,
            y: initialY)
        bug.zRotation = 0
        gameLayerNode.addChild(bug)

        let offsetX = random(min: size.width * 1 / 4, max: size.width)
        let deltaX = random(min: -offsetX, max: offsetX)
        let deltaY = topLimit - bottomLimit + bug.size.height / 2
        bug.zRotation -= atan(deltaX / deltaY)
        let duration = TimeInterval(random(
            min: random(min: 3, max: 4),
            max: random(min: 5, max: 6)))
        let actionMove =
            SKAction.moveBy(x: deltaX, y: deltaY, duration: duration)
        let actionRemove = SKAction.removeFromParent()
        bug.run(SKAction.sequence([actionMove, actionRemove]))
    }

    func spawnBugWave() {
        for _ in 0 ... 6 {
            gameLayerNode.run(SKAction.run(createTopBugs))
            gameLayerNode.run(SKAction.run(createBottomBugs))
            gameLayerNode.run(SKAction.run(createLeftBugs))
            gameLayerNode.run(SKAction.run(createRightBugs))
        }
    }
}

// MARK: - game play related

extension GameScene {
    func timeUp() {
        backgroundMusicPlayer.stop()
        gameEnded = true
        let gameOverScene = GameOverScene()
        gameOverScene.size = size
        gameOverScene.newbestScore = newbestScore
        gameOverScene.scaleMode = .aspectFill
        view?.presentScene(gameOverScene)
    }
}

// MARK: - Notifications

extension GameScene {
    func addObservers() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { [weak self] _ in
            self?.applicationDidBecomeActive()
        }
        notificationCenter.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: nil) { [weak self] _ in
            self?.applicationWillResignActive()
        }
        notificationCenter.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { [weak self] _ in
            self?.applicationDidEnterBackground()
        }
    }

    func applicationDidBecomeActive() {
        print("* applicationDidBecomeActive")
    }

    func applicationWillResignActive() {
        print("* applicationWillResignActive")
        gameState = .pause
    }

    func applicationDidEnterBackground() {
        print("* applicationDidEnterBackground")
        gameState = .pause
    }
}
