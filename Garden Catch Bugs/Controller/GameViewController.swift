//
//  GameViewController.swift
//  Garden: Catch Bugs
//
//  Created by Banghua Zhao on 5/24/20.
//  Copyright © 2020 Banghua Zhao. All rights reserved.
//

import GameplayKit
import SpriteKit
import UIKit

class GameViewController: UIViewController {
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let scene =
            MainMenuScene(size: CGSize(width: 2048, height: 1536))
        let skView = view as! SKView
        #if DEBUG
//            skView.showsFPS = true
//            skView.showsNodeCount = true
        #endif
        // Scene content is layered by parent/child order as well as zPosition, and this
        // game is far too small to need the unordered fast path.
        skView.ignoresSiblingOrder = false
        scene.scaleMode = .aspectFill
        skView.presentScene(scene)

        #if !targetEnvironment(macCatalyst)
            if adsAllowed {
                let banner = AdaptiveBannerView(rootViewController: self)
                banner.pinToBottom(of: view, safeArea: view.safeAreaLayoutGuide)
                gameBannerView = banner
            }
        #endif

        NotificationCenter.default.addObserver(
            forName: .adsEntitlementDidChange,
            object: nil,
            queue: .main
        ) { _ in
            MainActor.assumeIsolated { removeGameBannerIfPurchased() }
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
