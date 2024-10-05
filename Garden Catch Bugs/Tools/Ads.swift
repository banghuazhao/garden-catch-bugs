//
//  Ads.swift
//  Height Tracker
//
//  Created by Banghua Zhao on 2021/1/31.
//  Copyright © 2021 Banghua Zhao. All rights reserved.
//

import Foundation
import AppTrackingTransparency
import AdSupport


//NEWLY ADDED PERMISSIONS FOR iOS 14
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
//
