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

    lazy var backButton = UIButton(type: .custom).then { b in
        b.setImage(UIImage(named: "back_black"), for: .normal)
        b.addTarget(self, action: #selector(backToHome), for: .touchUpInside)
    }

    lazy var titleLabel = UILabel().then { label in
        label.font = UIFont.bigTitle
        label.textColor = .black
        label.text = "Settings".localized()
    }

    lazy var card = UIView().then { view in
        view.backgroundColor = UIColor.white.withAlphaComponent(0.82)
        view.layer.cornerRadius = 18
        view.layer.masksToBounds = true
    }

    lazy var musicRow = makeToggleRow(
        title: "Music".localized(),
        isOn: AudioSettings.isMusicEnabled,
        action: #selector(musicToggled))

    lazy var soundEffectsRow = makeToggleRow(
        title: "Sound Effects".localized(),
        isOn: AudioSettings.isSoundEffectsEnabled,
        action: #selector(soundEffectsToggled))

    lazy var separator = UIView().then { view in
        view.backgroundColor = UIColor.black.withAlphaComponent(0.12)
    }

    lazy var moreAppsButton = UIButton(type: .system).then { b in
        b.setTitle("More Apps".localized(), for: .normal)
        b.setTitleColor(.black, for: .normal)
        b.titleLabel?.font = UIFont.title
        b.contentHorizontalAlignment = .left
        b.addTarget(self, action: #selector(showMoreApps), for: .touchUpInside)
    }

    lazy var moreAppsArrow = UIImageView().then { imageView in
        imageView.tintColor = .black
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "chevron.right")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(patternImage: UIImage(named: "bg_2048x1536")!)
        view.addSubview(backButton)
        view.addSubview(titleLabel)
        view.addSubview(card)
        card.addSubview(musicRow)
        card.addSubview(separator)
        card.addSubview(soundEffectsRow)
        card.addSubview(moreAppsButton)
        card.addSubview(moreAppsArrow)

        #if !targetEnvironment(macCatalyst)
            AdaptiveBannerView(rootViewController: self)
                .pinToBottom(of: view, safeArea: view.safeAreaLayoutGuide)
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
        card.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.7).priority(.high)
            make.width.lessThanOrEqualTo(520)
        }
        musicRow.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(56)
        }
        separator.snp.makeConstraints { make in
            make.top.equalTo(musicRow.snp.bottom)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(1)
        }
        soundEffectsRow.snp.makeConstraints { make in
            make.top.equalTo(separator.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(56)
        }
        moreAppsButton.snp.makeConstraints { make in
            make.top.equalTo(soundEffectsRow.snp.bottom)
            make.left.equalToSuperview().inset(16)
            make.right.equalTo(moreAppsArrow.snp.left).offset(-8)
            make.height.equalTo(56)
            make.bottom.equalToSuperview()
        }
        moreAppsArrow.snp.makeConstraints { make in
            make.centerY.equalTo(moreAppsButton)
            make.right.equalToSuperview().inset(16)
            make.size.equalTo(16)
        }
    }
}

// MARK: - Rows

extension SettingsViewController {
    private func makeToggleRow(title: String, isOn: Bool, action: Selector) -> UIView {
        let row = UIView()

        let label = UILabel().then { label in
            label.text = title
            label.font = UIFont.title
            label.textColor = .black
        }
        let toggle = UISwitch().then { toggle in
            toggle.isOn = isOn
            toggle.onTintColor = UIColor(red: 0.19, green: 0.61, blue: 0.32, alpha: 1)
            toggle.addTarget(self, action: action, for: .valueChanged)
        }

        row.addSubview(label)
        row.addSubview(toggle)
        label.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        toggle.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.left.greaterThanOrEqualTo(label.snp.right).offset(12)
        }
        return row
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

    @objc func showMoreApps() {
        let moreApps = MoreAppsViewController()
        moreApps.modalPresentationStyle = .fullScreen
        present(moreApps, animated: true)
    }

    @objc func backToHome() {
        dismiss(animated: true)
    }
}
