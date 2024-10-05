//
//  GameOverScene.swift
//  Garden Catch Bugs
//
//  Created by Banghua Zhao on 5/24/20.
//  Copyright © 2020 Banghua Zhao. All rights reserved.
//

#if !targetEnvironment(macCatalyst)
    import GoogleMobileAds
#endif
import SpriteKit

class GameOverScene: SKScene {
    let tapSound = SKAction.playSoundFileNamed("按键.mp3", waitForCompletion: true)
    var newbestScore = 0

    override func didMove(to view: SKView) {
        #if !targetEnvironment(macCatalyst)
            bannerView.isHidden = false
        #endif

        #if !targetEnvironment(macCatalyst)
            GADInterstitialAd.load(withAdUnitID: Constants.interstitialAdID, request: GADRequest()) { ad, error in
                if let error = error {
                    print("Failed to load interstitial ad with error: \(error.localizedDescription)")
                    return
                }
                if let ad = ad {
                    if let rootViewController = view.window?.rootViewController {
                        ad.present(fromRootViewController: rootViewController)
                    }

                } else {
                    print("interstitial Ad wasn't ready")
                }
            }
        #else
            let moreAppsViewController = MoreAppsViewController()
            if let rootViewController = view.window?.rootViewController { rootViewController.present(moreAppsViewController, animated: true)
            }
        #endif

        playBackgroundMusic(filename: "胜利.mp3", repeatForever: false)
        let background = SKSpriteNode(imageNamed: "bg_2048x1536")
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(background)

        let gameOverMenu = SKSpriteNode(imageNamed: "gameOverMenu")
        gameOverMenu.zPosition = 200
        gameOverMenu.position = CGPoint(
            x: size.width / 2,
            y: size.height / 2 + 50)
        gameOverMenu.name = "gameOverMenu"
        addChild(gameOverMenu)

        let resultLabel = SKLabelNode(fontNamed: "Helvetica-Bold").then { node in
            node.text = "\("Your best score is".localized()): \(newbestScore)"
            node.fontColor = SKColor.black
            node.fontSize = 54
            node.zPosition = 100
            node.horizontalAlignmentMode = .center
            node.verticalAlignmentMode = .center
        }

        resultLabel.position = CGPoint(
            x: 0, y: 0)
        gameOverMenu.addChild(resultLabel)

        let backButton = SKSpriteNode(imageNamed: "button")
        backButton.position = CGPoint(
            x: 0, y: -180)
        backButton.zPosition = 2
        backButton.name = "backButton"
        gameOverMenu.addChild(backButton)

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

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let vTouch = touches.first else { return }
        let touchLocation = vTouch.location(in: self)

        let nodesAtPoint = nodes(at: touchLocation)

        for node in nodesAtPoint {
            if node.name == "backButton" {
                run(tapSound)
                let mainMenuScene = MainMenuScene()
                mainMenuScene.size = size
                mainMenuScene.scaleMode = .aspectFill
                view?.presentScene(mainMenuScene)
            }
        }
    }
}
