//
// Created by Vadim on 2019-03-13.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class TimeFrameSelectorView: UIControl {

    private let leftControl = UILabel()
    private let rightControl = UILabel()
    private let leftDimming = UIView()
    private let rightDimming = UIView()
    private let topBalk = UIView()
    private let bottomBalk = UIView()

    private let gesture = UILongPressGestureRecognizer()
    private var actionView: UIView?
    private var panPoint = CGPoint.zero
    private var shouldRecognize = false

    public weak var colorSource: MiniChartTimeSelectorViewColorSource? {
        didSet {
            reloadColors()
        }
    }

    public private(set) var selectedTimeRange: TimeRange?
    public private(set) var timeRange: TimeRange?

    public override init(frame: CGRect) {
        super.init(frame: frame)

        prepareControl(leftControl)
        prepareControl(rightControl)
        leftControl.transform = CGAffineTransform(scaleX: -1, y: 1)

        let controls = [leftDimming, rightDimming, leftControl, rightControl, topBalk, bottomBalk]
        controls.forEach { v in
            addSubview(v)
            v.isUserInteractionEnabled = false
        }

        gesture.addTarget(self, action: #selector(handleGesture))
        gesture.delegate = self
        gesture.minimumPressDuration = 0
        addGestureRecognizer(gesture)
        reloadColors()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    private var rect: CGRect {
        let bounds = self.bounds.insetBy(dx: 15, dy: 0) // TODO: pass as aurgument
        return bounds.insetBy(dx: 0, dy: 6)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        guard let timeRange = timeRange, gesture.state == .possible else {
            return
        }
        let selectedTimeRange = self.selectedTimeRange ?? timeRange
        let rect = self.rect
        let leftRange = timeRange.beforeTimestamp(selectedTimeRange.min)
        let rightRange = timeRange.afterTimestamp(selectedTimeRange.max)
        let calculator = DrawingChart.XCalculator(timeRange: timeRange)

        var (slice0, rest0) = rect.divided(atDistance: calculator.x(in: rect, timestamp: leftRange.max) - rect.minX, from: .minXEdge)
        (slice0, rest0) = rest0.divided(atDistance: 11, from: .minXEdge)
        let updateLeftControlCorners = leftControl.bounds.size != slice0.size
        leftControl.frame = slice0
        if updateLeftControlCorners {
            updateRoundedCorners(control: leftControl)
        }

        var (slice1, _) = rect.divided(atDistance: calculator.x(in: rect, timestamp: rightRange.min) - rect.minX, from: .minXEdge)

        var rest = rest0.intersection(slice1)
        (slice1, rest) = rest.divided(atDistance: 11, from: .maxXEdge)
        let updateRightControlCorners: Bool = rightControl.bounds.size != slice1.size
        rightControl.frame = slice1
        if updateRightControlCorners {
            updateRoundedCorners(control: rightControl)
        }

        layoutDimmingAndBalk()
    }

    private func layoutDimmingAndBalk() {
        let rect = self.rect
        var (slice, rest) = rect.divided(atDistance: leftControl.frame.minX - rect.minX, from: .minXEdge)
        leftDimming.frame = slice.insetBy(dx: 0, dy: 2)
        (slice, rest) = rest.divided(atDistance: leftControl.frame.width, from: .minXEdge)
        (slice, rest) = rest.divided(atDistance: rightControl.frame.minX - leftControl.frame.maxX, from: .minXEdge)
        topBalk.frame = slice.divided(atDistance: 1, from: .minYEdge).slice
        bottomBalk.frame = slice.divided(atDistance: 1, from: .maxYEdge).slice
        (slice, rest) = rect.divided(atDistance: rect.maxX - rightControl.frame.maxX, from: .maxXEdge)
        rightDimming.frame = slice.insetBy(dx: 0, dy: 2)
    }

    public func update(timeRange: TimeRange?, selectedTimeRange: TimeRange?) {
        self.timeRange = timeRange
        self.selectedTimeRange = selectedTimeRange
        setNeedsLayout()
    }

    public func reloadColors() {
        let chevronColor = self.chevronColor
        leftControl.textColor = chevronColor
        rightControl.textColor = chevronColor

        let dimmingColor = self.dimmingColor
        leftDimming.backgroundColor = dimmingColor
        rightDimming.backgroundColor = dimmingColor

        let controlColor = self.controlColor
        [leftControl, rightControl, topBalk, bottomBalk].forEach { $0.backgroundColor = controlColor }
    }

    private func prepareControl(_ control: UILabel) {
        control.text = "\u{203A}"
        control.textAlignment = .center
        control.clipsToBounds = true
    }

    private func updateRoundedCorners(control: UIView) {
        let path = UIBezierPath(
                roundedRect: control.bounds,
                byRoundingCorners: [.topRight, .bottomRight],
                cornerRadii: CGSize(width: 2, height: 2))

        let maskLayer = CAShapeLayer()
        maskLayer.frame = control.bounds
        maskLayer.path = path.cgPath
        control.layer.mask = maskLayer
    }

    @objc
    private func handleGesture() {
        let newPanPoint = gesture.location(in: self)
        switch gesture.state {
        case .began:
            updateActionView(point: newPanPoint)
            shouldRecognize = false
            setHighlighted(actionView != nil)

        case .changed:
            let d = abs(newPanPoint.x - panPoint.x) - abs(newPanPoint.y - panPoint.y)
            if shouldRecognize || (!shouldRecognize && d > 0) {
                shouldRecognize = true
                handleTranslation(point: newPanPoint)
            } else if d != 0 || actionView == nil {
                gesture.isEnabled = false
            }

        default:
            setHighlighted(false)
            gesture.isEnabled = true
            updateTimeRange()
            setNeedsLayout()
        }
    }

    private func setHighlighted(_ flag: Bool) {
        [leftControl, rightControl, topBalk, bottomBalk].forEach {
            $0.alpha = flag ? 0.7 : 1
        }
    }

    private func updateActionView(point: CGPoint) {
        panPoint = point
        let leftFrame = leftControl.frame.insetBy(dx: -10, dy: 0)
        let rightFrame = rightControl.frame.insetBy(dx: -10, dy: 0)
        if leftFrame.contains(point) && abs(leftFrame.midX - point.x) < abs(rightFrame.midX - point.x) {
            actionView = leftControl
        } else if rightFrame.contains(point) {
            actionView = rightControl
        } else if point.x > leftControl.center.x && point.x < rightControl.center.x {
            actionView = self
        } else {
            actionView = nil
        }
    }

    private func handleTranslation(point: CGPoint) {
        guard actionView != nil else {
            return
        }
        
        let bounds = rect
        let dx = point.x - panPoint.x
        var leftRect = leftControl.frame
        var rightRect = rightControl.frame

        let distance: CGFloat = 30 // TODO: get value from data
        if actionView == leftControl {
            leftRect = leftRect.offsetBy(dx: dx, dy: 0)
            if leftRect.minX < bounds.minX {
                leftRect.origin.x = bounds.minX
            }
            if leftRect.maxX + distance > rightRect.minX {
                leftRect.origin.x = rightRect.minX - distance - leftRect.width
            }
        } else if actionView == rightControl {
            rightRect = rightRect.offsetBy(dx: dx, dy: 0)
            if rightRect.maxX > bounds.maxX {
                rightRect.origin.x = bounds.maxX - rightRect.width
            }
            if leftRect.maxX + distance > rightRect.minX {
                rightRect.origin.x = leftRect.maxX + distance
            }
        } else if actionView == self {
            leftRect = leftRect.offsetBy(dx: dx, dy: 0)
            rightRect = rightRect.offsetBy(dx: dx, dy: 0)
            let d = rightRect.minX - leftRect.maxX
            if leftRect.minX < bounds.minX {
                leftRect.origin.x = bounds.minX
                rightRect.origin.x = leftRect.maxX + d
            } else if rightRect.maxX > bounds.maxX {
                rightRect.origin.x = bounds.maxX - rightRect.width
                leftRect.origin.x = rightRect.minX - d - leftRect.width
            }
        }

        leftControl.frame = leftRect
        rightControl.frame = rightRect
        layoutDimmingAndBalk()
        panPoint = point

        setNeedsUpdateTimeRange()
    }

    private var needsUpdateTimeRange = false
    private func setNeedsUpdateTimeRange() {
        guard !needsUpdateTimeRange else {
            return
        }
        needsUpdateTimeRange = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) { [weak self] in
            guard self?.needsUpdateTimeRange ?? false else {
                return
            }
            self?.updateTimeRange()
        }
    }

    private func updateTimeRange() {
        needsUpdateTimeRange = false
        guard let timeRange = timeRange else {
            return
        }
        let leftRect = leftControl.frame
        let rightRect = rightControl.frame
        // TODO: corners
        let bounds = rect
        let calculator = DrawingChart.XCalculator(timeRange: timeRange)
        let min = calculator.timestampAt(x: leftRect.minX, rect: bounds)
        let max = calculator.timestampAt(x: rightRect.maxX, rect: bounds)
        selectedTimeRange = TimeRange(min: min, max: max)
        sendActions(for: .valueChanged)
    }

    private var chevronColor: UIColor {
        return colorSource?.chevronColor(miniChartTimeSelectorView: self) ?? UIColor.white
    }

    private var dimmingColor: UIColor {
        return colorSource?.dimmingColor(miniChartTimeSelectorView: self) ?? UIColor.black.withAlphaComponent(0.1)
    }

    private var controlColor: UIColor {
        return colorSource?.controlColor(miniChartTimeSelectorView: self) ?? UIColor.black.withAlphaComponent(0.2)
    }
}

extension TimeFrameSelectorView: UIGestureRecognizerDelegate {
    public func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {

        return true
    }

    public func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {

        return true
    }
}

public protocol MiniChartTimeSelectorViewColorSource: AnyObject {
    func chevronColor(miniChartTimeSelectorView view: TimeFrameSelectorView) -> UIColor
    func dimmingColor(miniChartTimeSelectorView view: TimeFrameSelectorView) -> UIColor
    func controlColor(miniChartTimeSelectorView view: TimeFrameSelectorView) -> UIColor
}
