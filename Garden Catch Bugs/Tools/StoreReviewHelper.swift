//
//  StoreReviewHelper.swift
//  Financial Ratios Go
//
//  Created by Banghua Zhao on 12/2/19.
//  Copyright © 2019 Banghua Zhao. All rights reserved.
//

import Foundation
import StoreKit
import UIKit

struct StoreReviewHelper {
        
    static func incrementOpenCount() { // called from appdelegate didfinishLaunchingWithOptions:
        guard var openCount = UserDefaults.standard.value(forKey: Constants.UserDefaultsKeys.OPEN_COUNT) as? Int else {
            UserDefaults.standard.set(1, forKey: Constants.UserDefaultsKeys.OPEN_COUNT)
            return
        }
        openCount += 1
        UserDefaults.standard.set(openCount, forKey: Constants.UserDefaultsKeys.OPEN_COUNT)
    }
    static func checkAndAskForReview() { // call this whenever appropriate
        // this will not be shown everytime. Apple has some internal logic on how to show this.
        guard let openCount = UserDefaults.standard.value(forKey: Constants.UserDefaultsKeys.OPEN_COUNT) as? Int else {
            UserDefaults.standard.set(1, forKey: Constants.UserDefaultsKeys.OPEN_COUNT)
            return
        }
        
        switch openCount {
        case 5,25:
            StoreReviewHelper().requestReview()
        case _ where openCount%100 == 0 :
            StoreReviewHelper().requestReview()
        default:
            print("Open count is : \(openCount)")
            break;
        }
        
    }
    fileprivate func requestReview() {
        // The scene-less requestReview() was deprecated in iOS 14. Prefer the
        // active scene, falling back to any connected one; if UIKit has not
        // attached a scene yet this simply skips, which is fine because the
        // prompt is throttled by the App Store anyway.
        let windowScenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        guard let scene = windowScenes.first(where: { $0.activationState == .foregroundActive })
            ?? windowScenes.first else { return }
        SKStoreReviewController.requestReview(in: scene)
    }
}
