//
//  MainMenuScene.swift
//  Garden Catch Bugs
//

import Localize_Swift
import SpriteKit

let tapButtonSound = SKAction.playSoundFileNamed("按键.mp3", waitForCompletion: false)

let beeAnimation: SKAction = makeBugAnimation(prefix: "bee")
let ladyBugAnimation: SKAction = makeBugAnimation(prefix: "lady_bug")
let leafBeetleAnimation: SKAction = makeBugAnimation(prefix: "leafbeetle")
let starBeetleAnimation: SKAction = makeBugAnimation(prefix: "starbeetle")
let blueBeetleAnimation: SKAction = makeBugAnimation(prefix: "blue_beetle")
let stinkBugAnimation: SKAction = makeBugAnimation(prefix: "stinkbug")

private func makeBugAnimation(prefix: String) -> SKAction {
    var textures = (1 ... 5).map { SKTexture(imageNamed: "\(prefix)_\($0)") }
    textures.append(textures[3])
    textures.append(textures[2])
    textures.append(textures[1])
    return SKAction.animate(with: textures, timePerFrame: 0.1)
}

private enum MenuPalette {
    static let ink = SKColor(red: 0.06, green: 0.18, blue: 0.14, alpha: 1)
    static let forest = SKColor(red: 0.05, green: 0.28, blue: 0.20, alpha: 0.92)
    static let leaf = SKColor(red: 0.19, green: 0.61, blue: 0.32, alpha: 1)
    static let mint = SKColor(red: 0.73, green: 0.96, blue: 0.79, alpha: 1)
    static let cream = SKColor(red: 1.0, green: 0.97, blue: 0.84, alpha: 1)
    static let amber = SKColor(red: 0.94, green: 0.66, blue: 0.20, alpha: 1)
}

final class MainMenuScene: SKScene {
    private var modalIsVisible = false

    override func didMove(to view: SKView) {
        setGameBannerHidden(false)
        backgroundColor = MenuPalette.ink
        playBackgroundMusic(filename: "首页音乐.mp3", repeatForever: true)

        let background = SKSpriteNode(imageNamed: "bg_2048x1536")
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        background.name = "background"
        addChild(background)

        buildMenu(in: background)
        addShowcaseBugs(to: background)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let control = namedControl(at: touch.location(in: self)) else { return }

        if modalIsVisible {
            guard control.name == "backButton" else { return }
            animateButtonPress(control)
            playSoundEffect(tapButtonSound)
            hideHelp()
            return
        }

        switch control.name {
        case "startButton":
            startGame(mode: .classic, from: control)
        case "survivalButton":
            startGame(mode: .survival, from: control)
        case "helpButton":
            animateButtonPress(control)
            playSoundEffect(tapButtonSound)
            showHelp()
        case "settingsButton":
            animateButtonPress(control)
            playSoundEffect(tapButtonSound)
            let settingsViewController = SettingsViewController()
            settingsViewController.modalPresentationStyle = .fullScreen
            view?.window?.rootViewController?.present(settingsViewController, animated: true)
        default:
            break
        }
    }
}

// MARK: - Menu layout

extension MainMenuScene {
    private func buildMenu(in background: SKSpriteNode) {
        let panel = SKShapeNode(rectOf: CGSize(width: 900, height: 380), cornerRadius: 48)
        panel.position = CGPoint(x: -540, y: -20)
        panel.fillColor = MenuPalette.forest
        panel.strokeColor = MenuPalette.mint.withAlphaComponent(0.50)
        panel.lineWidth = 4
        panel.zPosition = 1
        panel.setScale(0.92)
        background.addChild(panel)
        panel.run(.sequence([
            .wait(forDuration: 0.08),
            .scale(to: 1.02, duration: 0.26),
            .scale(to: 1, duration: 0.16),
        ]))

        let title = SKSpriteNode(imageNamed: "title")
        title.position = CGPoint(x: 0, y: 378)
        title.zPosition = 4
        title.setScale(0.80)
        background.addChild(title)
        title.run(.repeatForever(.sequence([
            .moveBy(x: 0, y: 13, duration: 1.8),
            .moveBy(x: 0, y: -13, duration: 1.8),
        ])), withKey: "titleFloat")

        // 2x2 grid inside the panel: play modes on top, everything else below.
        let columnX: [CGFloat] = [-750, -330]
        let rowY: [CGFloat] = [50, -90]
        let buttons = [
            makeMenuButton(
                name: "startButton",
                title: "Classic".localized(),
                color: MenuPalette.leaf,
                position: CGPoint(x: columnX[0], y: rowY[0])),
            makeMenuButton(
                name: "survivalButton",
                title: "Survival".localized(),
                color: MenuPalette.amber,
                position: CGPoint(x: columnX[1], y: rowY[0])),
            makeMenuButton(
                name: "helpButton",
                title: "Help".localized(),
                color: MenuPalette.ink,
                position: CGPoint(x: columnX[0], y: rowY[1])),
            makeMenuButton(
                name: "settingsButton",
                title: "Settings".localized(),
                color: MenuPalette.ink,
                position: CGPoint(x: columnX[1], y: rowY[1])),
        ]
        buttons.forEach { button in
            button.zPosition = 3
            background.addChild(button)
        }
    }

    private func makeMenuButton(name: String, title: String, color: SKColor, position: CGPoint) -> SKShapeNode {
        let button = SKShapeNode(rectOf: CGSize(width: 380, height: 110), cornerRadius: 28)
        button.name = name
        button.position = position
        button.fillColor = color
        button.strokeColor = MenuPalette.cream.withAlphaComponent(0.7)
        button.lineWidth = 3

        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = title
        label.fontColor = MenuPalette.cream
        label.fontSize = 40
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = .zero
        label.zPosition = 1
        button.addChild(label)
        return button
    }

    private func addShowcaseBugs(to background: SKSpriteNode) {
        let bugs: [(String, SKAction, CGPoint, CGFloat, TimeInterval)] = [
            ("bee_1", beeAnimation, CGPoint(x: 155, y: 88), 0.88, 0),
            ("lady_bug_1", ladyBugAnimation, CGPoint(x: 470, y: 105), 0.84, 0.25),
            ("leafbeetle_1", leafBeetleAnimation, CGPoint(x: 750, y: 78), 0.92, 0.45),
            ("starbeetle_1", starBeetleAnimation, CGPoint(x: 150, y: -220), 0.88, 0.68),
            ("blue_beetle_1", blueBeetleAnimation, CGPoint(x: 455, y: -224), 0.86, 0.87),
            ("stinkbug_1", stinkBugAnimation, CGPoint(x: 750, y: -218), 0.72, 1.05),
        ]

        for (imageName, animation, position, scale, delay) in bugs {
            let bug = SKSpriteNode(imageNamed: imageName)
            bug.position = position
            bug.zPosition = 2
            bug.setScale(scale)
            bug.alpha = 0
            background.addChild(bug)
            bug.run(.repeatForever(animation), withKey: "flutter")
            bug.run(.sequence([
                .wait(forDuration: delay),
                .group([
                    .fadeIn(withDuration: 0.24),
                    .sequence([
                        .scale(to: scale * 1.08, duration: 0.18),
                        .scale(to: scale, duration: 0.16),
                    ]),
                ]),
            ]))
            bug.run(.repeatForever(.sequence([
                .wait(forDuration: delay),
                .moveBy(x: 0, y: 14, duration: 1.25),
                .moveBy(x: 0, y: -14, duration: 1.25),
            ])), withKey: "hover")
        }
    }
}

// MARK: - Help modal

extension MainMenuScene {
    private func showHelp() {
        guard !modalIsVisible else { return }
        modalIsVisible = true

        let overlay = SKNode()
        overlay.name = "helpOverlay"
        overlay.zPosition = 100
        addChild(overlay)

        let dimmer = SKShapeNode(rectOf: size)
        dimmer.position = CGPoint(x: size.width / 2, y: size.height / 2)
        dimmer.fillColor = SKColor.black.withAlphaComponent(0.55)
        dimmer.strokeColor = .clear
        dimmer.zPosition = 0
        overlay.addChild(dimmer)

        let helpCard = SKSpriteNode(imageNamed: "helpMenu")
        helpCard.position = CGPoint(x: size.width / 2, y: size.height / 2 + 30)
        helpCard.name = "helpCard"
        helpCard.zPosition = 1
        helpCard.setScale(0.76)
        overlay.addChild(helpCard)

        let back = makeMenuButton(
            name: "backButton",
            title: "Back".localized(),
            color: MenuPalette.leaf,
            position: CGPoint(x: 0, y: -370))
        back.zPosition = 1
        back.setScale(0.78)
        helpCard.addChild(back)

        helpCard.run(.sequence([
            .scale(to: 1.04, duration: 0.18),
            .scale(to: 1, duration: 0.14),
        ]), withKey: "enter")
    }

    private func hideHelp() {
        guard let overlay = childNode(withName: "helpOverlay") else {
            modalIsVisible = false
            return
        }
        // Stay modal until the overlay is gone, so the fade-out can't leak a tap
        // through to the menu buttons underneath.
        overlay.name = nil
        overlay.run(.sequence([
            .group([
                .fadeOut(withDuration: 0.16),
                .scale(to: 1.04, duration: 0.16),
            ]),
            .removeFromParent(),
        ])) { [weak self] in
            self?.modalIsVisible = false
        }
    }

    private func startGame(mode: GameMode, from control: SKNode) {
        animateButtonPress(control)
        playSoundEffect(tapButtonSound)
        endBackgroundMusic()
        let gameScene = GameScene(size: size, mode: mode)
        gameScene.scaleMode = .aspectFill
        view?.presentScene(gameScene, transition: .crossFade(withDuration: 0.26))
    }

    private func namedControl(at location: CGPoint) -> SKNode? {
        for node in nodes(at: location) {
            var candidate: SKNode? = node
            while let current = candidate {
                if ["startButton", "survivalButton", "helpButton", "settingsButton", "backButton"].contains(current.name ?? "") {
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
            .scale(to: 0.93, duration: 0.05),
            .scale(to: 1, duration: 0.14),
        ]), withKey: "press")
    }
}
