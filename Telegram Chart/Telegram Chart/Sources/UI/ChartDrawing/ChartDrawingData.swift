//
// Created by Vadim on 2019-03-13.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class DrawingChart {

    public let plots: [Chart.Plot]
    public let timestamps: [Chart.Time]
    public let timeRange: TimeRange
    public let selectedTimeRange: TimeRange
    public let valueRangeCalculation: ValueRangeCalculation
    public let yAxisCalculation: YAxisCalculation

    public init(plots: [Chart.Plot],
                timestamps: [Chart.Time],
                timeRange: TimeRange,
                selectedTimeRange: TimeRange? = nil,
                valueRangeCalculation: ValueRangeCalculation,
                yAxisCalculation: YAxisCalculation) {

        self.plots = plots
        self.timestamps = timestamps
        self.timeRange = timeRange
        self.selectedTimeRange = selectedTimeRange ?? timeRange
        self.valueRangeCalculation = valueRangeCalculation
        self.yAxisCalculation = yAxisCalculation
    }

    public private(set) lazy var indexRange: TimeIndexRange = {
        if selectedTimeRange != timeRange {
            return TimeIndexRange(timestamps: timestamps, timeRange: selectedTimeRange)
        } else {
            return TimeIndexRange(length: timestamps.count)
        }
    }()

    public private(set) lazy var valueRange: ValueRange = yAxis.valueRange
    public private(set) lazy var axisValues: YAxisValues = yAxis.yAxisValues

    public private(set) lazy var rawValueRange: ValueRange = {
        return valueRangeCalculation.valueRange(plots: plots, indexRange: indexRange)
    }()

    private lazy var yAxis: YAxisCalculationResult = {
        return yAxisCalculation.yAxis(valueRange: rawValueRange)
    }()

    public func closestIdxTo(timestamp: Int64) -> Int {
        if timestamp <= selectedTimeRange.min {
            return indexRange.startIdx
        }
        if timestamp >= selectedTimeRange.max {
            return indexRange.endIdx
        }
        var low = indexRange.startIdx
        var high = indexRange.endIdx
        while low != high {
            let mid = low + (high - low) / 2
            if timestamps[mid] <= timestamp && timestamp <= timestamps[mid + 1] {
                if timestamp - timestamps[mid] < timestamps[mid + 1] - timestamp {
                    return mid
                } else {
                    return mid + 1
                }
            }
            if timestamps[mid] < timestamp {
                low = mid + 1
            } else {
                high = mid
            }
        }
        return low
    }

    public struct XCalculator {
        public let timeRange: TimeRange

        public func x(in rect: CGRect, timestamp: Int64) -> CGFloat {
            let t = CGFloat(timestamp - timeRange.min) / CGFloat(timeRange.size)
            let x = rect.minX + rect.width * t
            return x
        }

        public func timestampAt(x: CGFloat, rect: CGRect) -> Int64 {
            let d = (x - rect.minX) / rect.width
            let timestamp = CGFloat(timeRange.min) + CGFloat(timeRange.size) * d
            return Int64(timestamp)
        }
    }

    public struct YCalculator {
        public let valueRange: ValueRange

        public func y(in rect: CGRect, value: Int64) -> CGFloat {
            let v = CGFloat(value - valueRange.min) / CGFloat(valueRange.size)
            let y = rect.minY + rect.size.height * v
            return rect.maxY + rect.minY - y
        }

        public func valueAt(y y0: CGFloat, rect: CGRect) -> Int64 {
            let y = rect.maxY + rect.minY - y0
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

public protocol ValueRangeCalculation {
    func valueRange(plots: [Chart.Plot], indexRange: TimeIndexRange) -> ValueRange
}

public protocol YAxisCalculation {
    func yAxis(valueRange: ValueRange) -> YAxisCalculationResult
}

public struct YAxisCalculationResult {
    let valueRange: ValueRange
    let yAxisValues: YAxisValues
}

public struct YAxisValues {
    public let zero: Chart.Value
    public let step: Chart.Value

    public static let no = YAxisValues(zero: -1, step: -1)
}

public struct TimeAxisDescription: Equatable {
    public var zeroIdx: Int
    public var step: Int
}

public struct ValueRangeNoYAxisStrategy: YAxisCalculation {
    public func yAxis(valueRange: ValueRange) -> YAxisCalculationResult {
        return YAxisCalculationResult(valueRange: valueRange, yAxisValues: .no)
    }
}

public struct ValueRangeHasYAxis: YAxisCalculation {

    private static let pows = [
        1,
        1_0,
        1_00,
        1_000,
        1_000_0,
        1_000_00,
        1_000_000,
        1_000_000_0,
        1_000_000_00,
        1_000_000_000,
    ]

    // TODO: fix draft IMPL
    public func yAxis(valueRange: ValueRange) -> YAxisCalculationResult {
        let sz = valueRange.size
        var p = 0
        let n = 5
        let ds = sz / Int64(n)
        let pows = ValueRangeHasYAxis.pows
        while ds > pows[p] {
            p += 1
        }
        let step: Int64
        if p > 1 {
            let t = pow(10.0, Double(p - 1))
            step = Int64(round(Double(ds) / t) * t)
        } else {
            step = max(1, sz / Int64(n))
        }
        let zero = valueRange.min / step * step
        return YAxisCalculationResult(
                valueRange: ValueRange(min: min(valueRange.min, zero), max: valueRange.max + step / 2),
                yAxisValues: YAxisValues(zero: zero, step: step))
    }
}

public struct StaticValueRangeCalculation: ValueRangeCalculation {
    public let valueRange: ValueRange

    public func valueRange(plots: [Chart.Plot], indexRange: TimeIndexRange) -> ValueRange {
        return valueRange
    }
}

public struct FullValueRangeCalculation: ValueRangeCalculation {
    public func valueRange(plots: [Chart.Plot], indexRange: TimeIndexRange) -> ValueRange {
        return ValueRange(ranges: plots.map { $0.valueRange } )
    }
}

public struct SelectedValueRangeCalculation: ValueRangeCalculation {
    public func valueRange(plots: [Chart.Plot], indexRange: TimeIndexRange) -> ValueRange {
        let ranges = plots.map { $0.valueRange(indexRange: indexRange) }
        return ValueRange(ranges: ranges)
    }
}

