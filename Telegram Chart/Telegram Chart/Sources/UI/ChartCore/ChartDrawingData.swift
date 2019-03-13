//
// Created by Vadim on 2019-03-13.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class DrawingChart {

    public let timestamps: [Int64]
    public let timeRange: TimeRange
    public let selectedTimeRange: TimeRange
    public let plots: [Chart.Plot]

    public init(timestamps: [Int64],
                timeRange: TimeRange,
                selectedTimeRange: TimeRange? = nil,
                plots: [Chart.Plot]) {
        self.timestamps = timestamps
        self.timeRange = timeRange
        self.selectedTimeRange = selectedTimeRange ?? timeRange
        self.plots = plots
    }

    public private(set) lazy var timeIndexRange: TimeIndexRange = {
        if selectedTimeRange != timeRange {
            return TimeIndexRange(timestamps: timestamps, timeRange: selectedTimeRange)
        } else {
            return TimeIndexRange(length: timestamps.count)
        }
    }()

    public private(set) lazy var valueRange: ValueRange = {
        let ranges = plots.map { $0.valueRange(indexRange: timeIndexRange) }
        return ValueRange(ranges: ranges)
    }()
}

public extension ValueRange {
    public func y(in rect: CGRect, value: Int64) -> CGFloat {
        let v = CGFloat(value - min) / CGFloat(size)
        let x = rect.minY + rect.size.height * v
        return x
    }
}

public extension TimeRange {
    public func x(in rect: CGRect, timestamp: Int64) -> CGFloat {
        let t = CGFloat(timestamp - min) / CGFloat(size)
        let x = rect.minX + rect.size.width * t
        return x
    }

    public func timestampAt(x: CGFloat, rect: CGRect) -> Int64 {
        let d = (x - rect.minX) / rect.size.width
        let timestamp = CGFloat(min) + CGFloat(size) * d
        return Int64(timestamp)
    }
}
