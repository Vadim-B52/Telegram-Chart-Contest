//
// Created by Vadim on 2019-03-13.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class MiniChartTimeSelectorView: UIControl {

    private let leftControl = UILabel()
    private let rightControl = UILabel()
    private let leftDimming = UIView()
    private let rightDimming = UIView()
    private let topBalk = UIView()
    private let bottomBalk = UIView()

    private let longPress = UILongPressGestureRecognizer()
    private var actionView: UIView?
    private var panPoint = CGPoint.zero

    public weak var colorSource: MiniChartTimeSelectorViewColorSource? {
        didSet {
            reloadColors()
        }
    }

    public var timeRange: TimeRange? {
        didSet {
            setNeedsLayout()
        }
    }
    public var selectedTimeRange: TimeRange? {
        didSet {
            setNeedsLayout()
        }
    }

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

        longPress.addTarget(self, action: #selector(handleLongPress))
        longPress.minimumPressDuration = 0.125
        addGestureRecognizer(longPress)
        reloadColors()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        guard let timeRange = timeRange else {
            return
        }
        let selectedTimeRange = self.selectedTimeRange ?? timeRange
        let bounds = self.bounds.insetBy(dx: 15, dy: 0) // TODO: pass as aurgument
        let rect = bounds.insetBy(dx: 0, dy: 6)
        let leftRange = timeRange.beforeTimestamp(selectedTimeRange.min)
        let rightRange = timeRange.afterTimestamp(selectedTimeRange.max)
        let calculator = DrawingChart.XCalculator(timeRange: timeRange)

        var (slice0, rest0) = rect.divided(atDistance: calculator.x(in: rect, timestamp: leftRange.max) - rect.minX, from: .minXEdge)
        leftDimming.frame = slice0.insetBy(dx: 0, dy: 2)
        (slice0, rest0) = rest0.divided(atDistance: 11, from: .minXEdge)
        let updateLeftControlCorners = leftControl.bounds.size != slice0.size
        leftControl.frame = slice0
        if updateLeftControlCorners {
            updateRoundedCorners(control: leftControl)
        }

        var (slice1, rest1) = rect.divided(atDistance: calculator.x(in: rect, timestamp: rightRange.min) - rect.minX, from: .minXEdge)
        rightDimming.frame = rest1.insetBy(dx: 0, dy: 2)

        var rest = rest0.intersection(slice1)
        (slice1, rest) = rest.divided(atDistance: 11, from: .maxXEdge)
        let updateRightControlCorners: Bool = rightControl.bounds.size != slice1.size
        rightControl.frame = slice1
        if updateRightControlCorners {
            updateRoundedCorners(control: rightControl)
        }

        (slice0, rest) = rest.divided(atDistance: 1, from: .minYEdge)
        (slice1, rest) = rest.divided(atDistance: 1, from: .maxYEdge)
        topBalk.frame = slice0
        bottomBalk.frame = slice1
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
    private func handleLongPress() {
        switch longPress.state {
        case .began:
            updateActionView(point: longPress.location(in: self))
            setHighlighted(actionView != nil)
            break
        case .changed:
            handleTranslation(point: longPress.location(in: self))
            break
        default:
            setHighlighted(false)
            break
        }
    }

    private func setHighlighted(_ flag: Bool) {
        [leftControl, rightControl, topBalk, bottomBalk].forEach {
            $0.alpha = flag ? 0.7 : 1
        }
    }

    private func updateActionView(point: CGPoint) {
        panPoint = point
        if leftControl.frame.inset(by: UIEdgeInsets(top: 0, left: -10, bottom: 0, right: -10)).contains(point) {
            actionView = leftControl
        } else if rightControl.frame.inset(by: UIEdgeInsets(top: 0, left: -10, bottom: 0, right: -10)).contains(point) {
            actionView = rightControl
        } else if point.x > leftControl.center.x && point.x < rightControl.center.x {
            actionView = self
        } else {
            actionView = nil
        }
    }

    private func handleTranslation(point: CGPoint) {
        guard actionView != nil,
              let timeRange = timeRange else {
            return
        }
        
        let bounds = self.bounds.insetBy(dx: 15, dy: 0) // TODO: pass as aurgument
        let dx = point.x - panPoint.x
        panPoint = point

        var leftRect = leftControl.frame
        var rightRect = rightControl.frame

        let distance: CGFloat = 30
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
        
    // TODO: corners
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

public protocol MiniChartTimeSelectorViewColorSource: AnyObject {
    func chevronColor(miniChartTimeSelectorView view: MiniChartTimeSelectorView) -> UIColor
    func dimmingColor(miniChartTimeSelectorView view: MiniChartTimeSelectorView) -> UIColor
    func controlColor(miniChartTimeSelectorView view: MiniChartTimeSelectorView) -> UIColor
}
