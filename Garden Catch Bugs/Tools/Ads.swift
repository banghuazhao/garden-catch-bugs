//
//  Ads.swift
//  Height Tracker
//
//  Created by Banghua Zhao on 2021/1/31.
//  Copyright © 2021 Banghua Zhao. All rights reserved.
//

import AdSupport
import AppTrackingTransparency
import Foundation
import UIKit
#if !targetEnvironment(macCatalyst)
    import GoogleMobileAds
#endif

func requestATTPermission() {
    ATTrackingManager.requestTrackingAuthorization { status in
        switch status {
        case .authorized:
            // Tracking authorization dialog was shown
            // and we are authorized
            print("Authorized")

            // Now that we are authorized we can get the IDFA
            print(ASIdentifierManager.shared().advertisingIdentifier)
        case .denied:
            // Tracking authorization dialog was
            // shown and permission is denied
            print("Denied")
        case .notDetermined:
            // Tracking authorization dialog has not been shown
            print("Not Determined")
        case .restricted:
            print("Restricted")
        @unknown default:
            print("Unknown")
        }
    }
}

#if !targetEnvironment(macCatalyst)
    /// An anchored adaptive banner that keeps its ad size in step with its width.
    ///
    /// AdMob drops requests made before `rootViewController` is set, and a banner
    /// with no `adSize` never sizes itself, so both are established here before the
    /// first request goes out. The request is repeated when the width actually
    /// changes (rotation, iPad multitasking) and not on every layout pass.
    final class AdaptiveBannerView: GADBannerView {
        static let maxHeight: CGFloat = 50

        private var requestedWidth: CGFloat = 0

        convenience init(rootViewController: UIViewController) {
            self.init(adSize: GADAdSizeBanner)
            adUnitID = Constants.bannerAdUnitID
            self.rootViewController = rootViewController
            translatesAutoresizingMaskIntoConstraints = false
        }

        /// Pins the banner to the bottom safe area. No width or height constraint:
        /// `GADBannerView` reports the ad size as its intrinsic size.
        func pinToBottom(of parent: UIView, safeArea: UILayoutGuide) {
            parent.addSubview(self)
            NSLayoutConstraint.activate([
                centerXAnchor.constraint(equalTo: parent.centerXAnchor),
                bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),
            ])
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            let width = superview?.bounds.width ?? bounds.width
            guard width > 0, abs(width - requestedWidth) > 1 else { return }
            requestedWidth = width
            // Anchored adaptive picks its own height, which reaches ~90pt on
            // iPad and eats the bottom of the playfield. Inline adaptive takes
            // a ceiling, so the banner still spans the full width but never
            // exceeds the standard 50pt bar.
            adSize = GADInlineAdaptiveBannerAdSizeWithWidthAndMaxHeight(width, AdaptiveBannerView.maxHeight)
            load(GADRequest())
        }
    }

    /// The banner living behind the SpriteKit scenes. Owned by GameViewController.
    weak var gameBannerView: AdaptiveBannerView?
#endif

/// The one rule every ad entry point consults: no SDK start, no load, no
/// display, and no reserved layout space once the shopper has bought removal.
///
/// Takes the controller as a parameter so the rule itself can be tested without
/// the singleton; `adsAllowed` is the app-wide convenience over it.
@MainActor
func areAdsAllowed(for purchases: PurchaseControlling) -> Bool {
    !purchases.isAdsRemoved
}

@MainActor
var adsAllowed: Bool {
    areAdsAllowed(for: PurchaseController.shared)
}

/// Shows or hides the banner that sits behind the SpriteKit scenes. Scenes call
/// this without caring whether ads are compiled in.
@MainActor
func setGameBannerHidden(_ hidden: Bool) {
    #if !targetEnvironment(macCatalyst)
        gameBannerView?.isHidden = hidden || !adsAllowed
    #endif
}

/// Tears the shared banner out of the hierarchy the moment the entitlement
/// arrives, so a purchase mid-session does not leave an ad on screen.
@MainActor
func removeGameBannerIfPurchased() {
    #if !targetEnvironment(macCatalyst)
        guard !adsAllowed else { return }
        gameBannerView?.removeFromSuperview()
        gameBannerView = nil
    #endif
}
