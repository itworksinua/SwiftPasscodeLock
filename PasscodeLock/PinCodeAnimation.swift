//
//  PinCodeAnimation.swift
//  PasscodeLock
//
//  Created by VitaliyK on 10/25/18.
//  Copyright © 2018 Yanko Dimitrov. All rights reserved.
//

import Foundation

// MARK: - Animations
public enum PinCodeShakeDirection {
    /// Shake left and right.
    case horizontal
    /// Shake up and down.
    case vertical
    
    static var `default`: PinCodeShakeDirection { return .horizontal }
}

public enum PinCodeShakeAnimationType {
    /// linear animation.
    case linear
    /// easeIn animation.
    case easeIn
    /// easeOut animation.
    case easeOut
    /// easeInOut animation.
    case easeInOut
    
    static var `default`: PinCodeShakeAnimationType { return .easeOut }
}

internal extension UIView {
    internal func shake(direction: PinCodeShakeDirection = .horizontal,
                        duration: TimeInterval = 1,
                        animationType: PinCodeShakeAnimationType = .linear,
                        swingLength: CGFloat = 20.0,
                        swingCount: Int = 4,
                        isDamping: Bool = true,
                        completion:(() -> Void)? = nil) {
        CATransaction.begin()
        let animation: CAKeyframeAnimation
        switch direction {
        case .horizontal:
            animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        case .vertical:
            animation = CAKeyframeAnimation(keyPath: "transform.translation.y")
        }
        switch animationType {
        case .linear:
            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        case .easeIn:
            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
        case .easeOut:
            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
        case .easeInOut:
            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        }
        CATransaction.setCompletionBlock(completion)
        animation.duration = duration
        
        let count = swingCount * 2
        var arr = [Int]()
        arr += -1...count
        let values: [Double] = arr.map {
            if $0 == -1 {
                return 0
            }
            let sign = $0 % 2 == 0 ? -1.0 : 1.0
            let div = isDamping ? pow(2.0, Double($0/2)) : 1.0
            return Double(($0 < count) ? (Double(swingLength) * sign) / div : Double(0.0))
        }
        
        animation.values = values
        
        layer.add(animation, forKey: "shake")
        CATransaction.commit()
    }
}
