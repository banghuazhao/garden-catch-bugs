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
#if !targetEnvironment(macCatalyst)
    import GoogleMobileAds
#endif
import SnapKit

#if !targetEnvironment(macCatalyst)
    var bannerView: GADBannerView = {
        let bannerView = GADBannerView()
        bannerView.adUnitID = Constants.bannerAdUnitID
        bannerView.load(GADRequest())
        return bannerView
    }()
#endif

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
        skView.ignoresSiblingOrder = true
        scene.scaleMode = .aspectFill
        skView.presentScene(scene)

        #if !targetEnvironment(macCatalyst)
            view.addSubview(bannerView)
            bannerView.rootViewController = self
            bannerView.snp.makeConstraints { make in
                make.height.equalTo(50)
                make.width.equalToSuperview()
                make.bottom.equalToSuperview()
                make.centerX.equalToSuperview()
            }
        #endif
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
