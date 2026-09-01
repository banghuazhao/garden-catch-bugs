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

// NEWLY ADDED PERMISSIONS FOR iOS 14
func requestATTPermission() {
    if #available(iOS 14, *) {
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
}

#if !targetEnvironment(macCatalyst)
    /// An anchored adaptive banner that keeps its ad size in step with its width.
    ///
    /// AdMob drops requests made before `rootViewController` is set, and a banner
    /// with no `adSize` never sizes itself, so both are established here before the
    /// first request goes out. The request is repeated when the width actually
    /// changes (rotation, iPad multitasking) and not on every layout pass.
    final class AdaptiveBannerView: GADBannerView {
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
            adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(width)
            load(GADRequest())
        }
    }

    /// The banner living behind the SpriteKit scenes. Owned by GameViewController.
    weak var gameBannerView: AdaptiveBannerView?
#endif

/// Shows or hides the banner that sits behind the SpriteKit scenes. Scenes call
/// this without caring whether ads are compiled in.
func setGameBannerHidden(_ hidden: Bool) {
    #if !targetEnvironment(macCatalyst)
        gameBannerView?.isHidden = hidden
    #endif
}
