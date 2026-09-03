//
//  AdConsent.swift
//  Garden Catch Bugs
//
//  Copyright © 2026 Banghua Zhao. All rights reserved.
//

import AppTrackingTransparency
import Foundation
import UIKit
#if !targetEnvironment(macCatalyst)
    import GoogleMobileAds
    import UserMessagingPlatform
#endif

#if !targetEnvironment(macCatalyst)

    extension Notification.Name {
        /// Posted once the consent flow has an answer, so anything that was
        /// waiting to request an ad can go ahead. Ad views listen for this
        /// rather than loading speculatively at layout time.
        static let adConsentDidResolve = Notification.Name("adConsentDidResolve")
    }

    /// The single source of truth for "may we track / may we serve personalized ads".
    ///
    /// Nothing else in the app is allowed to read `ATTrackingManager` or
    /// `UMPConsentInformation` and decide for itself. Every ad request is built
    /// by `makeRequest()`, and the ads SDK is not started until `resolve` has
    /// run, so no request can escape before the user has answered.
    ///
    /// Order follows Google's documented sequence: gather UMP consent first,
    /// then ask for ATT. The two answers are combined with "most restrictive
    /// wins", so whichever prompt the user sees first, a refusal in either one
    /// means non-personalized ads and no IDFA.
    @MainActor
    final class AdConsent {
        static let shared = AdConsent()

        private init() {}

        /// True once the flow has finished and ad requests may be built.
        private(set) var isResolved = false
        private var didStartFlow = false

        // MARK: - The resolver

        /// Whether the ads SDK may request anything at all. UMP says no while
        /// consent is required in the EEA/UK and has not been given.
        var canRequestAds: Bool {
            UMPConsentInformation.sharedInstance.canRequestAds
        }

        /// Whether those requests may be personalized. Needs consent *and* ATT.
        ///
        /// `.notDetermined` counts as "no": until the user has actually
        /// answered, the restrictive reading is the correct one.
        var canServePersonalizedAds: Bool {
            guard canRequestAds else { return false }
            guard UMPConsentInformation.sharedInstance.consentStatus != .required else { return false }
            return ATTrackingManager.trackingAuthorizationStatus == .authorized
        }

        /// The only way to build an ad request in this app.
        ///
        /// Tags the request non-personalized whenever the combined answer is
        /// anything short of a full yes, which is what stops a denial in either
        /// prompt from being quietly ignored.
        func makeRequest() -> GADRequest {
            let request = GADRequest()
            if !canServePersonalizedAds {
                let extras = GADExtras()
                extras.additionalParameters = ["npa": "1"]
                request.register(extras)
            }
            return request
        }

        /// Whether to offer a "Privacy Settings" row. Only users under a regime
        /// that required a consent form get one, which is what UMP reports.
        var isPrivacyOptionsRequired: Bool {
            UMPConsentInformation.sharedInstance.privacyOptionsRequirementStatus == .required
        }

        // MARK: - The flow

        /// Runs once per launch, from the first moment the app is foreground
        /// active. ATT is only requested from an active app -- asking earlier
        /// makes the system return `.denied` without ever showing the prompt.
        func resolve(from viewController: UIViewController?) {
            guard !didStartFlow else { return }
            didStartFlow = true

            let parameters = UMPRequestParameters()
            // The app is rated 4+ but is not directed at children and asks for
            // no age, so it cannot assert that the user is under the age of
            // consent. Flag stays false rather than being guessed.
            parameters.tagForUnderAgeOfConsent = false

            UMPConsentInformation.sharedInstance.requestConsentInfoUpdate(with: parameters) { [weak self] error in
                MainActor.assumeIsolated {
                    guard let self else { return }
                    if error != nil {
                        // A network failure must not become implied consent:
                        // `canRequestAds` stays false where consent was
                        // required, so the app simply shows no ads this launch.
                        self.finish()
                        return
                    }
                    self.presentConsentFormIfAppropriate(from: viewController)
                }
            }
        }

        /// Presents the UMP form -- unless ATT has already been refused.
        ///
        /// Asking a user who has just chosen "Ask App Not to Track" to consent
        /// to personalized ads is the contradiction Apple rejects apps for, so
        /// in that case the form is skipped entirely and ads stay
        /// non-personalized. The user has already given the restrictive answer;
        /// there is nothing left to ask.
        private func presentConsentFormIfAppropriate(from viewController: UIViewController?) {
            let attStatus = ATTrackingManager.trackingAuthorizationStatus
            guard attStatus != .denied, attStatus != .restricted else {
                finish()
                return
            }

            UMPConsentForm.loadAndPresentIfRequired(from: viewController) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.requestATTIfNeeded()
                }
            }
        }

        /// ATT comes second, per Google's documented order.
        private func requestATTIfNeeded() {
            guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else {
                finish()
                return
            }
            ATTrackingManager.requestTrackingAuthorization { _ in
                // The status itself is read back through the resolver; the app
                // never stores or logs the identifier.
                MainActor.assumeIsolated { self.finish() }
            }
        }

        /// Starts the ads SDK and releases anything waiting to load.
        private func finish() {
            isResolved = true
            if canRequestAds {
                GADMobileAds.sharedInstance().start(completionHandler: nil)
            }
            NotificationCenter.default.post(name: .adConsentDidResolve, object: nil)
        }

        // MARK: - Withdrawal

        /// Reopens the consent form so a choice can be changed at any time.
        /// Withdrawing is exactly as easy as giving.
        func presentPrivacyOptions(from viewController: UIViewController,
                                   completion: @escaping (Error?) -> Void) {
            UMPConsentForm.presentPrivacyOptionsForm(from: viewController) { error in
                MainActor.assumeIsolated {
                    // A change here takes effect on the next request, which the
                    // resolver builds fresh every time.
                    NotificationCenter.default.post(name: .adConsentDidResolve, object: nil)
                    completion(error)
                }
            }
        }

        #if DEBUG
            /// Wipes stored consent so the form can be seen again. Debug only --
            /// resetting in a shipping build would re-prompt users who have
            /// already answered.
            func resetForTesting() {
                UMPConsentInformation.sharedInstance.reset()
                didStartFlow = false
                isResolved = false
            }
        #endif
    }

#endif
