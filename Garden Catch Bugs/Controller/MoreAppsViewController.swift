//
//  MoreAppsViewController.swift
//  Financial Statements Go
//
//  Created by Banghua Zhao on 1/1/21.
//  Copyright © 2021 Banghua Zhao. All rights reserved.
//

import UIKit
#if !targetEnvironment(macCatalyst)
    import GoogleMobileAds
#endif

class MoreAppsViewController: UIViewController {
    var isAds: Bool = false

    #if !targetEnvironment(macCatalyst)
        lazy var bannerView: GADBannerView = {
            let bannerView = GADBannerView()
            bannerView.adUnitID = Constants.bannerAdUnitID
            bannerView.rootViewController = self
            bannerView.load(GADRequest())
            return bannerView
        }()

        let appItems = [
            AppItem(
                title: "Image Guru".localized(),
                detail: "Photo Editor,Filter".localized(),
                icon: UIImage(named: "image_guru"),
                url: URL(string: "http://itunes.apple.com/app/id1625021625")),
            AppItem(
                title: "Sudoku Lover".localized(),
                detail: "Sudoku Lover".localized(),
                icon: UIImage(named: "sudoku_lover"),
                url: URL(string: "http://itunes.apple.com/app/id1620749798")),
            AppItem(
                title: "We Play Piano".localized(),
                detail: "Piano Keyboard".localized(),
                icon: UIImage(named: "we_play_piano"),
                url: URL(string: "http://itunes.apple.com/app/id1625018611")),
            AppItem(
                title: "Saving Ambulance!Sliding Block".localized(),
                detail: "Sliding Puzzle With Cars".localized(),
                icon: UIImage(named: "saving_ambulance"),
                url: URL(string: "http://itunes.apple.com/app/id1639693525")),
            AppItem(
                title: "Fling Knife".localized(),
                detail: "Knife games".localized(),
                icon: UIImage(named: "fling_knife"),
                url: URL(string: "http://itunes.apple.com/app/id1636426217")),
            AppItem(
                title: "Relaxing Up".localized(),
                detail: "Meditation&Healing".localized(),
                icon: UIImage(named: "relaxing_up"),
                url: URL(string: "http://itunes.apple.com/app/id1618712178")),
            AppItem(
                title: "Mint Translate".localized(),
                detail: "Text Translator".localized(),
                icon: UIImage(named: "mint_translate"),
                url: URL(string: "http://itunes.apple.com/app/id1638456603")),
            AppItem(
                title: "Money Tracker".localized(),
                detail: "Budget, Expense & Bill Planner".localized(),
                icon: UIImage(named: "appIcon_moneyTracker"),
                url: URL(string: "http://itunes.apple.com/app/id\(Constants.moneyTrackerAppID)")),
            AppItem(
                title: "Minesweeper Z".localized(),
                detail: "Minesweeper App".localized(),
                icon: UIImage(named: "minesweeper_go"),
                url: URL(string: "http://itunes.apple.com/app/id1621899572")),
            AppItem(
                title: "Novels Hub".localized(),
                detail: "Fiction eBooks Library!".localized(),
                icon: UIImage(named: "appIcon_novels_Hub"),
                url: URL(string: "http://itunes.apple.com/app/id\(Constants.novelsHubAppID)")),
            AppItem(
                title: "More Apps".localized(),
                detail: "Check out more Apps made by us".localized(),
                icon: UIImage(named: "appIcon_appStore"),
                url: URL(string: "https://apps.apple.com/us/developer/%E7%92%90%E7%92%98-%E6%9D%A8/id1599035519")),
        ]
    #else
        let appItems = [
            AppItem(
                title: "Finance Go".localized(),
                detail: "Financial Reports & Investing".localized(),
                icon: UIImage(named: "appIcon_financeGo"),
                url: URL(string: "http://itunes.apple.com/app/id\(Constants.financeGoAppID)")),
            AppItem(
                title: "Ratios Go".localized(),
                detail: "Finance, Ratios, Investing".localized(),
                icon: UIImage(named: "appIcon_financialRatiosGo"),
                url: URL(string: "http://itunes.apple.com/app/id\(Constants.finanicalRatiosGoMacOSAppID)")),
            AppItem(
                title: "Money Tracker".localized(),
                detail: "Budget, Expense & Bill Planner".localized(),
                icon: UIImage(named: "appIcon_moneyTracker"),
                url: URL(string: "http://itunes.apple.com/app/id\(Constants.moneyTrackerAppID)")),
            AppItem(
                title: "BMI Diary".localized(),
                detail: "Fitness, Weight Loss &Health".localized(),
                icon: UIImage(named: "appIcon_bmiDiary"),
                url: URL(string: "http://itunes.apple.com/app/id\(Constants.BMIDiaryAppID)")),
            AppItem(
                title: "Novels Hub".localized(),
                detail: "Fiction eBooks Library!".localized(),
                icon: UIImage(named: "appIcon_novels_Hub"),
                url: URL(string: "http://itunes.apple.com/app/id\(Constants.novelsHubAppID)")),
            AppItem(
                title: "More Apps".localized(),
                detail: "Check out more Apps made by us".localized(),
                icon: UIImage(named: "appIcon_appStore"),
                url: URL(string: "https://apps.apple.com/us/developer/%E7%92%90%E7%92%98-%E6%9D%A8/id1599035519")),
        ]
    #endif

    lazy var backButton = UIButton(type: .custom).then { b in
        b.setImage(UIImage(named: "back_black"), for: .normal)
        b.addTarget(self, action: #selector(backToHome), for: .touchUpInside)
    }

    lazy var titleLabel = UILabel().then { label in
        label.font = UIFont.bigTitle
        label.textColor = .black
        if isAds {
            label.text = "More Apps (Ads)".localized()
        } else {
            label.text = "More Apps".localized()
        }
    }

    lazy var tableView = UITableView().then { tv in
        tv.backgroundColor = .clear
        tv.delegate = self
        tv.dataSource = self
        tv.register(AppItemCell.self, forCellReuseIdentifier: "AppItemCell")
        tv.register(MoreAppsHeaderCell.self, forCellReuseIdentifier: "MoreAppsHeaderCell")

        tv.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        tv.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 80))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = UIColor(patternImage: UIImage(named: "bg_2048x1536")!)
        view.addSubview(backButton)
        view.addSubview(titleLabel)
        view.addSubview(tableView)

        #if !targetEnvironment(macCatalyst)
            view.addSubview(bannerView)
            bannerView.snp.makeConstraints { make in
                make.bottom.equalTo(view.safeAreaLayoutGuide)
                make.left.right.equalToSuperview()
                make.height.equalTo(50)
            }
        #endif

        backButton.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(20)
            make.centerY.equalTo(titleLabel)
            make.size.equalTo(20)
        }
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
        }
        tableView.snp.makeConstraints { make in
            make.bottom.left.right.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
        }
    }
}

extension MoreAppsViewController {
    @objc func backToHome() {
        dismiss(animated: true, completion: nil)
    }
}

extension MoreAppsViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isAds {
            if section == 0 {
                return 1
            } else if section == 1 {
                return 1
            } else {
                return appItems.count
            }
        } else {
            if section == 0 {
                return 1
            } else {
                return appItems.count
            }
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MoreAppsHeaderCell", for: indexPath) as! MoreAppsHeaderCell
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AppItemCell", for: indexPath) as! AppItemCell
            cell.appItem = appItems[indexPath.row]
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            return
        } else {
            let appItem = appItems[indexPath.row]
            if let url = appItem.url, UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
}
