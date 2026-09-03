//
//  Ads.swift
//  Height Tracker
//
//  Created by Banghua Zhao on 2021/1/31.
//  Copyright © 2021 Banghua Zhao. All rights reserved.
//

import Foundation
import UIKit
#if !targetEnvironment(macCatalyst)
    import GoogleMobileAds
#endif


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

        private var consentObserver: NSObjectProtocol?

        convenience init(rootViewController: UIViewController) {
            self.init(adSize: GADAdSizeBanner)
            adUnitID = Constants.bannerAdUnitID
            self.rootViewController = rootViewController
            translatesAutoresizingMaskIntoConstraints = false
            // Laid out before the user has answered, the banner would otherwise
            // fire a request the consent flow has not authorised yet. Wait for
            // the answer, then request once.
            consentObserver = NotificationCenter.default.addObserver(
                forName: .adConsentDidResolve,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated { self?.requestIfPossible() }
            }
        }

        deinit {
            if let consentObserver {
                NotificationCenter.default.removeObserver(consentObserver)
            }
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
            requestIfPossible()
        }

        /// Sizes and requests, but only once consent has an answer and only
        /// when the width actually changed (rotation, iPad multitasking).
        private func requestIfPossible() {
            guard AdConsent.shared.isResolved, AdConsent.shared.canRequestAds else { return }
            let width = superview?.bounds.width ?? bounds.width
            guard width > 0, abs(width - requestedWidth) > 1 else { return }
            requestedWidth = width
            // Anchored adaptive picks its own height, which reaches ~90pt on
            // iPad and eats the bottom of the playfield. Inline adaptive takes
            // a ceiling, so the banner still spans the full width but never
            // exceeds the standard 50pt bar.
            adSize = GADInlineAdaptiveBannerAdSizeWithWidthAndMaxHeight(width, AdaptiveBannerView.maxHeight)
            load(AdConsent.shared.makeRequest())
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
