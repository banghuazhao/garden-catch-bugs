//
//  Constants.swift
//  Crazy Pyramid
//
//  Created by Banghua Zhao on 12/19/19.
//  Copyright © 2019 Banghua Zhao. All rights reserved.
//

import UIKit

struct Constants {
    static let isIPhone: Bool = UIDevice.current.userInterfaceIdiom == .phone

    static let countdownDaysAppID = "1525084657"
    static let moneyTrackerAppID = "1534244892"
    static let financeGoAppID = "1519476344"
    static let financialRatiosGoAppID = "1481582303"
    static let finanicalRatiosGoMacOSAppID = "1486184864"
    static let BMIDiaryAppID = "1521281509"
    static let fourGreatClassicalNovelsAppID = "1526758926"
    static let novelsHubAppID = "1528820845"
    static let nasaLoverID = "1595232677"
    
    static let bannerAdUnitID = Bundle.main.object(forInfoDictionaryKey: "BannerAdUnitID") as? String ?? ""
    static let interstitialAdID = Bundle.main.object(forInfoDictionaryKey: "InterstitialAdID") as? String ?? ""
    static let rewardAdUnitID = Bundle.main.object(forInfoDictionaryKey: "rewardAdUnitID") as? String ?? ""
    static let appOpenAdID = Bundle.main.object(forInfoDictionaryKey: "AppOpenAdID") as? String ?? ""

    struct UserDefaultsKeys {
        static let OPEN_COUNT = "OPEN_COUNT"
        static let BEST_SCORE = "BEST_SCORE"
    }

    static var isIphoneFaceID: Bool {
        if let topInset = UIApplication.shared.delegate?.window??.safeAreaInsets.top, topInset <= 24 {
            return false
        } else {
            return true
        }
    }
}
