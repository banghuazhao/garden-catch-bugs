//
//  AppDelegate.swift
//  Garden Catch Bugs
//
//  Created by Banghua Zhao on 5/24/20.
//  Copyright © 2020 Banghua Zhao. All rights reserved.
//

import UIKit
#if !targetEnvironment(macCatalyst)
    import GoogleMobileAds
#endif

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        PurchaseController.shared.start()

        #if !targetEnvironment(macCatalyst)
            // The ads SDK is deliberately NOT started here. `AdConsent` starts
            // it only after consent has an answer, so no request can go out
            // before the user has been asked. A purchaser never starts it at all.
        #else
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.forEach { windowScene in
                windowScene.sizeRestrictions?.maximumSize = CGSize(width: 1280, height: 720)
            }
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.forEach { windowScene in
                windowScene.sizeRestrictions?.minimumSize = CGSize(width: 1280, height: 720)
            }
        #endif

        StoreReviewHelper.incrementOpenCount()
        StoreReviewHelper.checkAndAskForReview()

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Covers backgrounding, the app switcher, Control Centre and calls.
        // Handled here rather than per-scene so no screen can forget: the menu
        // used to keep its music playing after the app was backgrounded.
        pauseBackgroundMusic()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // `resumeBackgroundMusic` is a no-op while the round is paused or the
        // player has muted music, so this cannot start audio unexpectedly.
        resumeBackgroundMusic()

        #if !targetEnvironment(macCatalyst)
            // Consent is gathered from here because ATT is only shown to a
            // foreground-active app; asked any earlier the system silently
            // returns `.denied`. `resolve` is idempotent, so returning from the
            // background never re-prompts.
            if adsAllowed {
                let root = window?.rootViewController
                AdConsent.shared.resolve(from: root?.presentedViewController ?? root)
            }
        #endif
    }
}
