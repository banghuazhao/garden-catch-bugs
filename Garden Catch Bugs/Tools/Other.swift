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
