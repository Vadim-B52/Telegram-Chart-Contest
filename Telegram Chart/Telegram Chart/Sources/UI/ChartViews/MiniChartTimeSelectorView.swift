//
// Created by Vadim on 2019-03-13.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class MiniChartTimeSelectorView: UIControl {

    private let leftControl = UIView()
    private let rightControl = UIView()
    private let leftDimming = UIView()
    private let rightDimming = UIView()
    private let topBalk = UIView()
    private let bottomBalk = UIView()

    private let longPress = UILongPressGestureRecognizer()
    private var actionView: UIView?
    private var panPoint = CGPoint.zero

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

        func prepareControl(_ control: UIView) {
            control.layer.cornerRadius = 2
            control.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            control.addSubview(label)
            label.text = "\u{203A}"
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: control.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: control.centerYAnchor),
            ])
        }

        prepareControl(leftControl)
        prepareControl(rightControl)
        leftControl.transform = CGAffineTransform(scaleX: -1, y: 1)

        let controls = [leftDimming, rightDimming, leftControl, rightControl, topBalk, bottomBalk]
        controls.forEach { v in
            addSubview(v)
            v.isUserInteractionEnabled = false
        }

        let dimmingColor = UIColor.black.withAlphaComponent(0.1)
        let color = UIColor.black.withAlphaComponent(0.2)

        leftDimming.backgroundColor = dimmingColor
        rightDimming.backgroundColor = dimmingColor
        [leftControl, rightControl, topBalk, bottomBalk].forEach { $0.backgroundColor = color }

        longPress.addTarget(self, action: #selector(handleLongPress))
        longPress.minimumPressDuration = 0.1
        addGestureRecognizer(longPress)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        guard let timeRange = timeRange,
              let selectedTimeRange = selectedTimeRange else {

            return
        }

        let rect = bounds.insetBy(dx: 0, dy: 6)
        let leftRange = timeRange.beforeTimestamp(selectedTimeRange.min)
        let rightRange = timeRange.afterTimestamp(selectedTimeRange.max)
        let calculator = DrawingChart.XCalculator(timeRange: timeRange)

        var (slice0, rest0) = rect.divided(atDistance: calculator.x(in: rect, timestamp: leftRange.max), from: .minXEdge)
        leftDimming.frame = slice0.insetBy(dx: 0, dy: 2)
        (slice0, rest0) = rest0.divided(atDistance: 11, from: .minXEdge)
        leftControl.frame = slice0

        var (slice1, rest1) = rect.divided(atDistance: calculator.x(in: rect, timestamp: rightRange.min), from: .minXEdge)
        rightDimming.frame = rest1.insetBy(dx: 0, dy: 2)

        var rest = rest0.intersection(slice1)
        (slice1, rest) = rest.divided(atDistance: 11, from: .maxXEdge)
        rightControl.frame = slice1

        (slice0, rest) = rest.divided(atDistance: 1, from: .minYEdge)
        (slice1, rest) = rest.divided(atDistance: 1, from: .maxYEdge)
        topBalk.frame = slice0
        bottomBalk.frame = slice1
    }

    @objc
    private func handleLongPress() {
        switch longPress.state {
        case .began:
            updateActionView(point: longPress.location(in: self))
            break
        case .changed:
            handleTranslation(point: longPress.location(in: self))
            break
        default:
            break
        }
    }

    private func updateActionView(point: CGPoint) {
        // TODO: extend touch area
        panPoint = point
        if leftControl.frame.contains(point) {
            actionView = leftControl
        } else if rightControl.frame.contains(point) {
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

        let dx = point.x - panPoint.x
        panPoint = point

        var leftRect = leftControl.frame
        var rightRect = rightControl.frame

        if actionView == leftControl {
            leftRect = leftRect.offsetBy(dx: dx, dy: 0)
        } else if actionView == rightControl {
            rightRect = rightRect.offsetBy(dx: dx, dy: 0)
        } else if actionView == self {
            leftRect = leftRect.offsetBy(dx: dx, dy: 0)
            rightRect = rightRect.offsetBy(dx: dx, dy: 0)
        }

        // TODO: corner positions
        let calculator = DrawingChart.XCalculator(timeRange: timeRange)
        if bounds.contains(leftRect) && bounds.contains(rightRect) && leftRect.maxX + 30 <= rightRect.minX {
            let min = calculator.timestampAt(x: leftRect.minX, rect: bounds)
            let max = calculator.timestampAt(x: rightRect.maxX, rect: bounds)
            selectedTimeRange = TimeRange(min: min, max: max)
            sendActions(for: .valueChanged)
        }
    }
}
