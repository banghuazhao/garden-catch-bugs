//
//  MainMenuScene.swift
//  Garden: Catch Bugs
//
//  Created by Banghua Zhao on 5/24/20.
//  Copyright © 2020 Banghua Zhao. All rights reserved.
//

import Foundation
import Localize_Swift
import SpriteKit
import Then

let tapButtonSound = SKAction.playSoundFileNamed("按键.mp3", waitForCompletion: true)

var beeAnimation: SKAction = {
    var textures: [SKTexture] = []
    for i in 1 ... 5 {
        textures.append(SKTexture(imageNamed: "bee_\(i)"))
    }
    textures.append(textures[3])
    textures.append(textures[2])
    textures.append(textures[1])
    return SKAction.animate(with: textures, timePerFrame: 0.1)
}()

var ladyBugAnimation: SKAction = {
    var textures: [SKTexture] = []
    for i in 1 ... 5 {
        textures.append(SKTexture(imageNamed: "lady_bug_\(i)"))
    }
    textures.append(textures[3])
    textures.append(textures[2])
    textures.append(textures[1])
    return SKAction.animate(with: textures, timePerFrame: 0.1)
}()

var leafBeetleAnimation: SKAction = {
    var textures: [SKTexture] = []
    for i in 1 ... 5 {
        textures.append(SKTexture(imageNamed: "leafbeetle_\(i)"))
    }
    textures.append(textures[3])
    textures.append(textures[2])
    textures.append(textures[1])
    return SKAction.animate(with: textures, timePerFrame: 0.1)
}()

var starBeetleAnimation: SKAction = {
    var textures: [SKTexture] = []
    for i in 1 ... 5 {
        textures.append(SKTexture(imageNamed: "starbeetle_\(i)"))
    }
    textures.append(textures[3])
    textures.append(textures[2])
    textures.append(textures[1])
    return SKAction.animate(with: textures, timePerFrame: 0.1)
}()

var blueBeetleAnimation: SKAction = {
    var textures: [SKTexture] = []
    for i in 1 ... 5 {
        textures.append(SKTexture(imageNamed: "blue_beetle_\(i)"))
    }
    textures.append(textures[3])
    textures.append(textures[2])
    textures.append(textures[1])
    return SKAction.animate(with: textures, timePerFrame: 0.1)
}()

var stinkBugAnimation: SKAction = {
    var textures: [SKTexture] = []
    for i in 1 ... 5 {
        textures.append(SKTexture(imageNamed: "stinkbug_\(i)"))
    }
    textures.append(textures[3])
    textures.append(textures[2])
    textures.append(textures[1])
    return SKAction.animate(with: textures, timePerFrame: 0.1)
}()

class MainMenuScene: SKScene {
    // MARK: - didMove

    override func didMove(to view: SKView) {
        #if !targetEnvironment(macCatalyst)
            bannerView.isHidden = false
        #endif
        playBackgroundMusic(filename: "首页音乐.mp3", repeatForever: true)

        let background = SKSpriteNode(imageNamed: "bg_2048x1536")
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(background)

        let title = SKSpriteNode(imageNamed: "title")
        title.position = CGPoint(x: 0, y: 300)
        title.zPosition = 2
        title.name = "title"
        background.addChild(title)

        let startButton = SKSpriteNode(imageNamed: "button")
        startButton.position = CGPoint(x: -500, y: 80)
        startButton.zPosition = 2
        startButton.name = "startButton"
        background.addChild(startButton)
        let startLabel = SKLabelNode(fontNamed: "Helvetica-Bold").then { node in
            node.text = "Start".localized()
            node.fontColor = SKColor.black
            node.fontSize = 50
            node.zPosition = 100
            node.horizontalAlignmentMode = .center
            node.verticalAlignmentMode = .center
            node.position = CGPoint(x: 0, y: 0)
        }
        startButton.addChild(startLabel)

        let helpButton = SKSpriteNode(imageNamed: "button")
        helpButton.position = CGPoint(x: -500, y: -70)
        helpButton.zPosition = 2
        helpButton.name = "helpButton"
        background.addChild(helpButton)

        let helpLabel = SKLabelNode(fontNamed: "Helvetica-Bold").then { node in
            node.text = "Help".localized()
            node.fontColor = SKColor.black
            node.fontSize = 50
            node.zPosition = 100
            node.horizontalAlignmentMode = .center
            node.verticalAlignmentMode = .center
            node.position = CGPoint(x: 0, y: 0)
        }

        helpButton.addChild(helpLabel)

        let creditsButton = SKSpriteNode(imageNamed: "button")
        creditsButton.position = CGPoint(x: -500, y: -220)
        creditsButton.zPosition = 2
        creditsButton.name = "creditsButton"
        background.addChild(creditsButton)

        let creditsLabel = SKLabelNode(fontNamed: "Helvetica-Bold").then { node in
            node.text = "More Apps".localized()
            node.fontColor = SKColor.black
            node.fontSize = 50
            node.zPosition = 100
            node.horizontalAlignmentMode = .center
            node.verticalAlignmentMode = .center
            node.position = CGPoint(x: 0, y: 0)
        }

        creditsButton.addChild(creditsLabel)

        let bee = SKSpriteNode(imageNamed: "bee_1")
        bee.position = CGPoint(x: 90, y: 40)
        bee.zPosition = 2
        bee.name = "bee"
        bee.run(SKAction.repeatForever(beeAnimation))
        background.addChild(bee)

        let ladyBug = SKSpriteNode(imageNamed: "lady_bug_1")
        ladyBug.position = CGPoint(x: 370, y: 40)
        ladyBug.zPosition = 2
        ladyBug.name = "ladyBug"
        ladyBug.run(SKAction.repeatForever(ladyBugAnimation))
        background.addChild(ladyBug)

        let leafBeetle = SKSpriteNode(imageNamed: "leafbeetle_1")
        leafBeetle.position = CGPoint(x: 650, y: 40)
        leafBeetle.zPosition = 2
        leafBeetle.name = "leafBeetle"
        leafBeetle.run(SKAction.repeatForever(leafBeetleAnimation))
        background.addChild(leafBeetle)

        let starBeetle = SKSpriteNode(imageNamed: "starbeetle_1")
        starBeetle.position = CGPoint(x: 90, y: -200)
        starBeetle.zPosition = 2
        starBeetle.name = "starBeetle"
        starBeetle.run(SKAction.repeatForever(starBeetleAnimation))
        background.addChild(starBeetle)

        let blueBeetle = SKSpriteNode(imageNamed: "blue_beetle_1")
        blueBeetle.position = CGPoint(x: 370, y: -200)
        blueBeetle.zPosition = 2
        blueBeetle.name = "blueBeetle"
        blueBeetle.run(SKAction.repeatForever(blueBeetleAnimation))
        background.addChild(blueBeetle)

        let stinkBug = SKSpriteNode(imageNamed: "stinkbug_1")
        stinkBug.position = CGPoint(x: 650, y: -200)
        stinkBug.zPosition = 2
        stinkBug.name = "stinkBug"
        stinkBug.run(SKAction.repeatForever(stinkBugAnimation))
        background.addChild(stinkBug)
    }

    // MARK: - touchesBegan

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)
        let nodesAtPoint = nodes(at: touchLocation)
        for node in nodesAtPoint {
            if node.name == "startButton" {
                backgroundMusicPlayer.stop()
                run(tapButtonSound)
                let gameScene = GameScene()
                gameScene.size = size
                gameScene.scaleMode = .aspectFill
                view?.presentScene(gameScene)
            } else if node.name == "helpButton" {
                run(tapButtonSound)
                let helpMenu = SKSpriteNode(imageNamed: "helpMenu")
                helpMenu.zPosition = 200
                helpMenu.position = CGPoint(
                    x: size.width / 2,
                    y: size.height / 2 + 20)
                helpMenu.name = "helpMenu"
                addChild(helpMenu)
                let backButton = SKSpriteNode(imageNamed: "button")
                backButton.position = CGPoint(
                    x: 0, y: -300)
                backButton.zPosition = 2
                backButton.name = "backButton"
                helpMenu.addChild(backButton)

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
            } else if node.name == "backButton" {
                run(tapButtonSound)
                enumerateChildNodes(withName: "helpMenu") { node, _ in
                    node.removeFromParent()
                }
                enumerateChildNodes(withName: "creditMenu") { node, _ in
                    node.removeFromParent()
                }
            } else if node.name == "creditsButton" {
                run(tapButtonSound)
                view?.window?.rootViewController?.present(MoreAppsViewController(), animated: true, completion: nil)
//                let helpMenu = SKSpriteNode(imageNamed: "creditMenu")
//                helpMenu.zPosition = 200
//                helpMenu.position = CGPoint(
//                    x: size.width / 2,
//                    y: size.height / 2)
//                helpMenu.name = "creditMenu"
//                addChild(helpMenu)
//
//                let backButton = SKSpriteNode(imageNamed: "button")
//                backButton.position = CGPoint(
//                    x: 0, y: -150)
//                backButton.zPosition = 2
//                backButton.name = "backButton"
//                helpMenu.addChild(backButton)
//
//                let backLabel = SKLabelNode(fontNamed: "Helvetica-Bold").then { node in
//                    node.text = "Back".localized()
//                    node.fontColor = SKColor.black
//                    node.fontSize = 50
//                    node.zPosition = 100
//                    node.horizontalAlignmentMode = .center
//                    node.verticalAlignmentMode = .center
//                    node.position = CGPoint(x: 0, y: 0)
//                }
//                backButton.addChild(backLabel)
            }
        }
    }
}
