//
//  PinCodeWrongAnimationOption.swift
//  PasscodeLock
//
//  Created by VitaliyK on 10/25/18.
//  Copyright © 2018 Yanko Dimitrov. All rights reserved.
//

import Foundation

public typealias PinCodeShakeAnimationOptions = Array<PinCodeShakeAnimationOptionItem>

public let PinCodeShakeAnimationOptionsDefault: PinCodeShakeAnimationOptions = [
    .direction(.default),
    .duration(1.0),
    .animationType(.easeOut),
    .swingLength(20.0),
    .swingCount(4),
    .isDamping(true)
]

public enum PinCodeShakeAnimationOptionItem {
    /// default 'horizontal'
    case direction(PinCodeShakeDirection)

    /// default '1.0'
    case duration(TimeInterval)

    /// default 'easeOut'
    case animationType(PinCodeShakeAnimationType)

    /// default '20.0'
    case swingLength(Double)

    /// default '4'
    case swingCount(Int)

    /// default 'true'
    case isDamping(Bool)
}


precedencegroup ItemComparisonPrecedence {
    associativity: none
    higherThan: LogicalConjunctionPrecedence
}

infix operator <== : ItemComparisonPrecedence

func <== (lhs: PinCodeShakeAnimationOptionItem, rhs: PinCodeShakeAnimationOptionItem) -> Bool {
    switch (lhs, rhs) {
    case (.direction(_), .direction(_)): return true
    case (.duration(_), .duration(_)): return true
    case (.animationType(_), .animationType(_)): return true
    case (.swingLength(_), .swingLength(_)): return true
    case (.swingCount(_), .swingCount(_)): return true
    case (.isDamping(_), .isDamping(_)): return true
    default: return false
    }
}


extension Collection where Iterator.Element == PinCodeShakeAnimationOptionItem {
    func lastMatchIgnoringAssociatedValue(_ target: Iterator.Element) -> Iterator.Element? {
        return reversed().first { $0 <== target }
    }
    
    func removeAllMatchesIgnoringAssociatedValue(_ target: Iterator.Element) -> [Iterator.Element] {
        return filter { !($0 <== target) }
    }
}

public extension Collection where Iterator.Element == PinCodeShakeAnimationOptionItem {
    public var direction: PinCodeShakeDirection {
        if let item = lastMatchIgnoringAssociatedValue(.direction(.default)),
            case .direction(let direction) = item
        {
            return direction
        }
        return .default
    }
    
    public var duration: TimeInterval {
        if let item = lastMatchIgnoringAssociatedValue(.duration(TimeInterval(1.0))),
            case .duration(let duration) = item
        {
            return duration
        }
        return TimeInterval(1.0)
    }
    
    public var animationType: PinCodeShakeAnimationType {
        if let item = lastMatchIgnoringAssociatedValue(.animationType(.default)),
            case .animationType(let animationType) = item
        {
            return animationType
        }
        return .default
    }
    
    public var swingLength: CGFloat {
        if let item = lastMatchIgnoringAssociatedValue(.swingLength(20.0)),
            case .swingLength(let swingLength) = item
        {
            return CGFloat(swingLength)
        }
        return 20.0
    }
    
    public var swingCount: Int {
        if let item = lastMatchIgnoringAssociatedValue(.swingCount(4)),
            case .swingCount(let swingCount) = item
        {
            return swingCount
        }
        return 4
    }
    
    public var isDamping: Bool {
        if let item = lastMatchIgnoringAssociatedValue(.isDamping(true)),
            case .isDamping(let isDamping) = item
        {
            return isDamping
        }
        return true
    }
}
