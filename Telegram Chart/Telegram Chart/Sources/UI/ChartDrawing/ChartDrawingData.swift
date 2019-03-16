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

    public func changeSelectedTimeRange(_ range: TimeRange?) -> DrawingChart {
        return DrawingChart(timestamps: timestamps, timeRange: timeRange, selectedTimeRange: range, plots: plots)
    }

    public struct XCalculator {
        public let timeRange: TimeRange

        public func x(in rect: CGRect, timestamp: Int64) -> CGFloat {
            let t = CGFloat(timestamp - timeRange.min) / CGFloat(timeRange.size)
            let x = rect.minX + rect.size.width * t
            return x
        }

        public func timestampAt(x: CGFloat, rect: CGRect) -> Int64 {
            let d = (x - rect.minX) / rect.size.width
            let timestamp = CGFloat(timeRange.min) + CGFloat(timeRange.size) * d
            return Int64(timestamp)
        }
    }

    public struct YCalculator {
        public let valueRange: ValueRange

        public func y(in rect: CGRect, value: Int64) -> CGFloat {
            let v = CGFloat(value - valueRange.min) / CGFloat(valueRange.size)
            let y = rect.minY + rect.size.height * v
            return rect.size.height - y
        }

        public func valueAt(y y0: CGFloat, rect: CGRect) -> Int64 {
            let y = rect.size.height - y0
            let d = (y - rect.minY) / rect.size.height
            let v = CGFloat(valueRange.min) + CGFloat(valueRange.size) * d
            return Int64(v)
        }
    }

    public struct Calculator {
        public let timeRange: TimeRange
        public let valueRange: ValueRange

        public func pointAtTimestamp(_ timestamp: Int64, value: Int64, rect: CGRect) -> CGPoint {
            let xCalc = XCalculator(timeRange: timeRange)
            let yCalc = YCalculator(valueRange: valueRange)
            let x = xCalc.x(in: rect, timestamp: timestamp)
            let y = yCalc.y(in: rect, value: value)
            return CGPoint(x: x, y: y)
        }
    }
}
