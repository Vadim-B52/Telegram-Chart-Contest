//
// Created by Vadim on 2019-03-13.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class TimeSelectorView: UIView {

    private let leftControl = UIView()
    private let rightControl = UIView()
    private let leftDimming = UIView()
    private let rightDimming = UIView()
    private let topBalk = UIView()
    private let bottomBalk = UIView()

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
        addSubview(leftDimming)
        addSubview(rightDimming)
        addSubview(leftControl)
        addSubview(rightControl)
        addSubview(topBalk)
        addSubview(bottomBalk)

        let dimmingColor = UIColor.black.withAlphaComponent(0.1)
        let color = UIColor.black.withAlphaComponent(0.2)

        leftDimming.backgroundColor = dimmingColor
        rightDimming.backgroundColor = dimmingColor
        [leftControl, rightControl, topBalk, bottomBalk].forEach { $0.backgroundColor = color }
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

        let leftRange = timeRange.beforeTimestamp(selectedTimeRange.min)
        let rightRange = timeRange.afterTimestamp(selectedTimeRange.max)

        var (slice0, rest0) = bounds.divided(atDistance: timeRange.x(in: bounds, timestamp: leftRange.max), from: .minXEdge)
        leftDimming.frame = slice0
        (slice0, rest0) = rest0.divided(atDistance: 11, from: .minXEdge)
        leftControl.frame = slice0

        var (slice1, rest1) = bounds.divided(atDistance: timeRange.x(in: bounds, timestamp: rightRange.min), from: .minXEdge)
        rightDimming.frame = rest1

        var rest = rest0.intersection(slice1)
        (slice1, rest) = rest.divided(atDistance: 11, from: .maxXEdge)
        rightControl.frame = slice1

        (slice0, rest) = rest.divided(atDistance: 1, from: .minYEdge)
        (slice1, rest) = rest.divided(atDistance: 1, from: .maxYEdge)
        topBalk.frame = slice0
        bottomBalk.frame = slice1
    }
}

