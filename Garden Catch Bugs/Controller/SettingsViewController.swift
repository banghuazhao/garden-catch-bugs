//
//  SettingsViewController.swift
//  Garden Catch Bugs
//
//  Copyright © 2026 Banghua Zhao. All rights reserved.
//

import Localize_Swift
import SnapKit
import Then
import UIKit
#if !targetEnvironment(macCatalyst)
    import GoogleMobileAds
#endif

class SettingsViewController: UIViewController {
    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }

    private let purchases: PurchaseControlling
    private var settingsBanner: UIView?
    private var entitlementObserver: NSObjectProtocol?

    /// `nil` resolves to the shared controller. A default argument cannot be
    /// used here: default arguments evaluate in a nonisolated context, which
    /// cannot touch the main-actor-isolated singleton.
    @MainActor
    init(purchases: PurchaseControlling? = nil) {
        self.purchases = purchases ?? PurchaseController.shared
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        if let entitlementObserver {
            NotificationCenter.default.removeObserver(entitlementObserver)
        }
    }

    lazy var backButton = UIButton(type: .custom).then { b in
        b.setImage(UIImage(named: "back_black"), for: .normal)
        b.addTarget(self, action: #selector(backToHome), for: .touchUpInside)
    }

    lazy var titleLabel = UILabel().then { label in
        label.font = UIFont.bigTitle
        label.textColor = .black
        label.text = "Settings".localized()
    }

    lazy var scrollView = UIScrollView().then { scrollView in
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
    }

    lazy var card = UIView().then { view in
        view.backgroundColor = UIColor.white.withAlphaComponent(0.82)
        view.layer.cornerRadius = 18
        view.layer.masksToBounds = true
    }

    lazy var stack = UIStackView().then { stack in
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .equalSpacing
    }

    lazy var musicRow = makeToggleRow(
        title: "Music".localized(),
        isOn: AudioSettings.isMusicEnabled,
        action: #selector(musicToggled))

    lazy var soundEffectsRow = makeToggleRow(
        title: "Sound Effects".localized(),
        isOn: AudioSettings.isSoundEffectsEnabled,
        action: #selector(soundEffectsToggled))

    lazy var removeAdsRow = makeActionRow(
        title: "Remove Ads".localized(),
        action: #selector(removeAdsTapped))

    lazy var restoreRow = makeActionRow(
        title: "Restore Purchases".localized(),
        action: #selector(restoreTapped))

    lazy var moreAppsRow = makeActionRow(
        title: "More Apps".localized(),
        action: #selector(showMoreApps),
        accessory: UIImageView(image: UIImage(systemName: "chevron.right")).then { $0.tintColor = .black })

    /// Reopens the consent form. Shown only where a consent form was required
    /// in the first place, which is what UMP reports.
    lazy var privacySettingsRow = makeActionRow(
        title: "Privacy Settings".localized(),
        action: #selector(privacySettingsTapped),
        accessory: UIImageView(image: UIImage(systemName: "chevron.right")).then { $0.tintColor = .black })

    lazy var privacyPolicyRow = makeActionRow(
        title: "Privacy Policy".localized(),
        action: #selector(privacyPolicyTapped),
        accessory: UIImageView(image: UIImage(systemName: "arrow.up.right")).then { $0.tintColor = .black })

    lazy var spinner = UIActivityIndicatorView(style: .medium).then { spinner in
        spinner.hidesWhenStopped = true
        spinner.color = .black
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(patternImage: UIImage(named: "bg_2048x1536")!)
        view.addSubview(backButton)
        view.addSubview(titleLabel)
        view.addSubview(scrollView)
        scrollView.addSubview(card)
        card.addSubview(stack)
        view.addSubview(spinner)

        // The Mac build has no ads, so Remove Ads and Restore Purchases have
        // nothing to act on and are left out entirely.
        #if targetEnvironment(macCatalyst)
            var rows = [musicRow, soundEffectsRow, moreAppsRow]
        #else
            var rows = [musicRow, soundEffectsRow, removeAdsRow, restoreRow, moreAppsRow]
            if AdConsent.shared.isPrivacyOptionsRequired {
                rows.append(privacySettingsRow)
            }
        #endif
        rows.append(privacyPolicyRow)

        for (index, row) in rows.enumerated() {
            if index > 0 { stack.addArrangedSubview(makeSeparator()) }
            stack.addArrangedSubview(row)
            row.snp.makeConstraints { make in make.height.equalTo(56) }
        }

        #if !targetEnvironment(macCatalyst)
            if adsAllowed {
                let banner = AdaptiveBannerView(rootViewController: self)
                banner.pinToBottom(of: view, safeArea: view.safeAreaLayoutGuide)
                settingsBanner = banner
            }
        #endif

        backButton.snp.makeConstraints { make in
            make.left.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.centerY.equalTo(titleLabel)
            make.size.equalTo(20)
        }
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
        }
        // The content scrolls so a short landscape screen -- or the banner
        // sitting over the bottom of it -- can never make a row unreachable.
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.left.right.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalToSuperview()
        }
        card.snp.makeConstraints { make in
            make.top.equalTo(scrollView.contentLayoutGuide).offset(8)
            make.bottom.equalTo(scrollView.contentLayoutGuide).offset(-8)
            make.centerX.equalTo(scrollView.frameLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide).multipliedBy(0.7).priority(.high)
            make.width.lessThanOrEqualTo(520)
        }
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        spinner.snp.makeConstraints { make in
            make.center.equalTo(scrollView.frameLayoutGuide)
        }

        #if !targetEnvironment(macCatalyst)
            entitlementObserver = NotificationCenter.default.addObserver(
                forName: .adsEntitlementDidChange,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated { self?.applyEntitlementState() }
            }
        #endif

        #if !targetEnvironment(macCatalyst)
            applyEntitlementState()
            Task {
                await purchases.loadProducts()
                applyEntitlementState()
            }
        #endif
    }
}

// MARK: - Rows

extension SettingsViewController {
    private func makeSeparator() -> UIView {
        UIView().then { view in
            view.backgroundColor = UIColor.black.withAlphaComponent(0.12)
            view.snp.makeConstraints { make in make.height.equalTo(1) }
        }
    }

    private func makeToggleRow(title: String, isOn: Bool, action: Selector) -> UIView {
        let toggle = UISwitch().then { toggle in
            toggle.isOn = isOn
            toggle.onTintColor = UIColor(red: 0.19, green: 0.61, blue: 0.32, alpha: 1)
            toggle.addTarget(self, action: action, for: .valueChanged)
        }
        return makeRow(title: title, accessory: toggle)
    }

    private func makeActionRow(title: String, action: Selector, accessory: UIView? = nil) -> UIView {
        let row = makeRow(title: title, accessory: accessory)
        row.addGestureRecognizer(UITapGestureRecognizer(target: self, action: action))
        row.isUserInteractionEnabled = true
        return row
    }

    /// Every row is a title on the left and one accessory on the right, so the
    /// detail label can be swapped for a price or a purchased marker later.
    private func makeRow(title: String, accessory: UIView?) -> UIView {
        let row = UIView()

        let label = UILabel().then { label in
            label.text = title
            label.font = UIFont.title
            label.textColor = .black
        }
        row.addSubview(label)
        label.tag = Self.titleTag
        label.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }

        let detail = UILabel().then { label in
            label.font = UIFont.normal
            label.textColor = .darkGray
            label.textAlignment = .right
        }
        detail.tag = Self.detailTag
        row.addSubview(detail)

        if let accessory {
            row.addSubview(accessory)
            accessory.snp.makeConstraints { make in
                make.right.equalToSuperview().inset(16)
                make.centerY.equalToSuperview()
            }
            detail.snp.makeConstraints { make in
                make.right.equalTo(accessory.snp.left).offset(-10)
                make.centerY.equalToSuperview()
                make.left.greaterThanOrEqualTo(label.snp.right).offset(12)
            }
        } else {
            detail.snp.makeConstraints { make in
                make.right.equalToSuperview().inset(16)
                make.centerY.equalToSuperview()
                make.left.greaterThanOrEqualTo(label.snp.right).offset(12)
            }
        }
        return row
    }

    private static let titleTag = 8001
    private static let detailTag = 8002

    private func titleLabel(in row: UIView) -> UILabel? { row.viewWithTag(Self.titleTag) as? UILabel }
    private func detailLabel(in row: UIView) -> UILabel? { row.viewWithTag(Self.detailTag) as? UILabel }
}

// MARK: - Entitlement state

extension SettingsViewController {
    private func applyEntitlementState() {
        if purchases.isAdsRemoved {
            titleLabel(in: removeAdsRow)?.text = "Ads Removed".localized()
            detailLabel(in: removeAdsRow)?.text = "✓"
            removeAdsRow.isUserInteractionEnabled = false
            removeAdsRow.alpha = 0.6
            settingsBanner?.removeFromSuperview()
            settingsBanner = nil
        } else {
            titleLabel(in: removeAdsRow)?.text = "Remove Ads".localized()
            // Never invent a price: show the store's own string, or say so.
            detailLabel(in: removeAdsRow)?.text = purchases.removeAdsDisplayPrice ?? "Unavailable".localized()
            removeAdsRow.isUserInteractionEnabled = true
            removeAdsRow.alpha = 1
        }
    }

    private func setBusy(_ busy: Bool) {
        busy ? spinner.startAnimating() : spinner.stopAnimating()
        card.alpha = busy ? 0.5 : 1
        card.isUserInteractionEnabled = !busy
    }

    /// Keep the last row clear of the banner rather than letting it sit under.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let bannerHeight = settingsBanner?.bounds.height ?? 0
        let clearance = bannerHeight + (bannerHeight > 0 ? 12 : 0)
        scrollView.contentInset.bottom = clearance
        scrollView.verticalScrollIndicatorInsets.bottom = clearance
    }

    private func showMessage(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK".localized(), style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Actions

extension SettingsViewController {
    @objc func musicToggled(_ sender: UISwitch) {
        AudioSettings.isMusicEnabled = sender.isOn
    }

    @objc func soundEffectsToggled(_ sender: UISwitch) {
        AudioSettings.isSoundEffectsEnabled = sender.isOn
    }

    @objc func removeAdsTapped() {
        guard !purchases.isAdsRemoved else { return }
        setBusy(true)
        Task {
            defer { setBusy(false) }
            do {
                switch try await purchases.buyRemoveAds() {
                case .purchased:
                    applyEntitlementState()
                    removeGameBannerIfPurchased()
                    showMessage("Ads Removed".localized(), "Thanks! Ads are gone for good.".localized())
                case .cancelled:
                    break
                case .pending:
                    showMessage("Waiting for Approval".localized(),
                                "Your purchase needs approval before it can finish.".localized())
                }
            } catch PurchaseError.productUnavailable {
                showMessage("Unavailable".localized(),
                            "Remove Ads is unavailable right now. Please try again later.".localized())
            } catch {
                showMessage("Purchase Failed".localized(),
                            "Something went wrong. Please try again.".localized())
            }
        }
    }

    @objc func restoreTapped() {
        setBusy(true)
        Task {
            defer { setBusy(false) }
            do {
                switch try await purchases.restorePurchases() {
                case .restored:
                    applyEntitlementState()
                    removeGameBannerIfPurchased()
                    showMessage("Purchases Restored".localized(), "Your purchase has been restored.".localized())
                case .nothingToRestore:
                    showMessage("Nothing to Restore".localized(),
                                "No previous purchase was found for this Apple Account.".localized())
                case .cancelled:
                    break
                }
            } catch {
                showMessage("Purchase Failed".localized(),
                            "Something went wrong. Please try again.".localized())
            }
        }
    }

    @objc func showMoreApps() {
        let moreApps = MoreAppsViewController()
        moreApps.modalPresentationStyle = .fullScreen
        present(moreApps, animated: true)
    }

    @objc func privacySettingsTapped() {
        #if !targetEnvironment(macCatalyst)
            setBusy(true)
            AdConsent.shared.presentPrivacyOptions(from: self) { [weak self] error in
                guard let self else { return }
                setBusy(false)
                if error != nil {
                    showMessage("Unavailable".localized(),
                                "Privacy settings are unavailable right now. Please try again later.".localized())
                }
            }
        #endif
    }

    @objc func privacyPolicyTapped() {
        guard let url = URL(string: Constants.privacyPolicyURL) else { return }
        UIApplication.shared.open(url)
    }

    @objc func backToHome() {
        dismiss(animated: true)
    }
}
