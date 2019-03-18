//
// Created by Vadim on 2019-03-19.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class ChartViewAnimator {
    private weak var displayLink: CADisplayLink?
    private var startTime: CFTimeInterval!
    public let animationDuration: CFTimeInterval
    public let startValue: Value
    public let endValue: Value
    public  var callback: ((Bool, Value) -> Void)?

    deinit {
        displayLink?.invalidate()
    }

    public init(animationDuration: TimeInterval, startValue: Value, endValue: Value) {
        self.animationDuration = animationDuration
        self.startValue = startValue
        self.endValue = endValue
    }

    public func startAnimation() {
        let displayLink = CADisplayLink(target: self, selector: #selector(onRenderTime))
        displayLink.preferredFramesPerSecond = 25
        displayLink.add(to: RunLoop.main, forMode: .common) // TODO: validate
        self.displayLink = displayLink
        self.startTime = CACurrentMediaTime()
    }

    public func endAnimation() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc
    private func onRenderTime() {
        let timeElapsed = CACurrentMediaTime() - startTime
        if timeElapsed >= animationDuration {
            callback?(true, endValue)
            endAnimation()
            return
        }
        var currentValue = startValue
        let minD = endValue.valueRange.min - startValue.valueRange.min
        let maxD = endValue.valueRange.max - startValue.valueRange.max
        let alphaD = endValue.alpha - startValue.alpha
        let elapsed = timeElapsed / animationDuration
        currentValue.valueRange = ValueRange(
                min: startValue.valueRange.min + Int64(elapsed * CFTimeInterval(minD)),
                max: startValue.valueRange.max + Int64(elapsed * CFTimeInterval(maxD)))
        currentValue.alpha = startValue.alpha + CGFloat(elapsed * CFTimeInterval(alphaD))
        callback?(false, currentValue)
    }

    public struct Value {
        public var valueRange: ValueRange
        public var alpha: CGFloat
    }
}
