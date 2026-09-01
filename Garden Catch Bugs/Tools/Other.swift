//
//  Other.swift
//  Garden Catch Bugs
//
//  Created by Banghua Zhao on 5/24/20.
//  Copyright © 2020 Banghua Zhao. All rights reserved.
//

import CoreGraphics
import Foundation
import SpriteKit
import UIKit

public func delay(seconds: TimeInterval, completion: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: completion)
}

public func random(min: CGFloat, max: CGFloat) -> CGFloat {
    return CGFloat(Float(arc4random()) / Float(0xFFFFFFFF))
        * (max - min) + min
}

extension CGFloat {
    static func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / Float(UInt32.max))
    }

    static func random(min: CGFloat, max: CGFloat) -> CGFloat {
        assert(min < max)
        return CGFloat.random() * (max - min) + min
    }
}

extension SKScene {
    /// The view's safe-area insets expressed in scene units.
    ///
    /// With `.aspectFill` the scene is scaled by whichever axis needs the most
    /// magnification, so dividing by that scale converts points back into the
    /// scene's own coordinate space. Landscape phones put a real notch inset on
    /// one side and the home indicator on the other, and neither is optional to
    /// respect: content placed at a raw scene edge lands underneath them.
    /// The part of the scene actually on screen once `.aspectFill` has cropped
    /// the overflowing axis.
    func visibleSceneRect() -> CGRect {
        guard let view, size.width > 0, size.height > 0 else {
            return CGRect(origin: .zero, size: size)
        }
        let scale = max(view.bounds.width / size.width, view.bounds.height / size.height)
        guard scale > 0 else { return CGRect(origin: .zero, size: size) }

        let visibleWidth = min(size.width, view.bounds.width / scale)
        let visibleHeight = min(size.height, view.bounds.height / scale)
        return CGRect(
            x: (size.width - visibleWidth) / 2,
            y: (size.height - visibleHeight) / 2,
            width: visibleWidth,
            height: visibleHeight)
    }

    /// Height of the ad banner currently covering the bottom of the scene, in
    /// scene units. The banner is a UIKit view sitting over the SKView, so a
    /// scene has no other way to know it is there.
    func sceneBannerHeight() -> CGFloat {
        #if targetEnvironment(macCatalyst)
            return 0
        #else
            guard let view, let banner = gameBannerView,
                  banner.superview != nil, !banner.isHidden,
                  size.width > 0, size.height > 0 else { return 0 }
            let scale = max(view.bounds.width / size.width, view.bounds.height / size.height)
            guard scale > 0 else { return 0 }
            return banner.bounds.height / scale
        #endif
    }

    /// Where scene content may safely be placed: on screen, inside the safe
    /// area, and clear of anything covering the bottom edge.
    func safeContentRect(reservingBottom reserved: CGFloat = 0) -> CGRect {
        let visible = visibleSceneRect()
        let insets = sceneSafeAreaInsets()
        let bottom = insets.bottom + reserved
        return CGRect(
            x: visible.minX + insets.left,
            y: visible.minY + bottom,
            width: max(0, visible.width - insets.left - insets.right),
            height: max(0, visible.height - insets.top - bottom))
    }

    func sceneSafeAreaInsets() -> UIEdgeInsets {
        guard let view, size.width > 0, size.height > 0 else { return .zero }
        let scale = max(view.bounds.width / size.width, view.bounds.height / size.height)
        guard scale > 0 else { return .zero }
        let insets = view.safeAreaInsets
        return UIEdgeInsets(
            top: insets.top / scale,
            left: insets.left / scale,
            bottom: insets.bottom / scale,
            right: insets.right / scale)
    }
}
