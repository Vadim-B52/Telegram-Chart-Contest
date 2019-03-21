//
// Created by Vadim on 2019-03-13.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class DrawingChart {

    public let plots: [Chart.Plot]
    public let timestamps: [Int64]
    public let timeRange: TimeRange
    public let selectedTimeRange: TimeRange
    public let valueRangeCalculation: DrawingValuesCalculation

    public init(plots: [Chart.Plot],
                timestamps: [Int64],
                timeRange: TimeRange,
                selectedTimeRange: TimeRange? = nil,
                valueRangeCalculation: DrawingValuesCalculation) {

        self.plots = plots
        self.timestamps = timestamps
        self.timeRange = timeRange
        self.selectedTimeRange = selectedTimeRange ?? timeRange
        self.valueRangeCalculation = valueRangeCalculation
    }

    public private(set) lazy var indexRange: TimeIndexRange = {
        if selectedTimeRange != timeRange {
            return TimeIndexRange(timestamps: timestamps, timeRange: selectedTimeRange)
        } else {
            return TimeIndexRange(length: timestamps.count)
        }
    }()

    public private(set) lazy var valueRange: ValueRange = yAxis.valueRange
    public private(set) lazy var yAxisValues: [Int64] = yAxis.axisValues

    private lazy var yAxis: DrawingValuesCalculationResult = {
        return self.valueRangeCalculation.drawingValues(plots: plots, indexRange: indexRange)
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

    public class Formatter {

        private lazy var popupFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter
        }()

        func popupDateText(timestamp: Int64) -> NSAttributedString {
            let date = Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
            return NSAttributedString(string: popupFormatter.string(from: date))
        }

        func popupValueText(index idx: Int, plots: [Chart.Plot]) -> NSAttributedString {
            let str = NSMutableAttributedString()
            for plot in plots {
                let attrs = [NSAttributedString.Key.foregroundColor: plot.color]
                let value = NSAttributedString(string: "\(plot.values[idx])\n", attributes: attrs)
                str.append(value)
            }
            str.replaceCharacters(in: NSRange(location: str.length - 1, length: 1), with: "")
            return str
        }
    }
}

public protocol DrawingValuesCalculation {
    func drawingValues(plots: [Chart.Plot], indexRange: TimeIndexRange) -> DrawingValuesCalculationResult
}

public struct DrawingValuesCalculationResult {
    let valueRange: ValueRange
    let axisValues: [Int64]

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

    // TODO: draft implementation!
    public init(valueRange: ValueRange) {
        var values = [Int64]()
        let sz = valueRange.size
        var p = 0
        let n: Int64 = 5
        let ds = sz / n
        let pows = DrawingValuesCalculationResult.pows
        while ds > pows[p] {
            p += 1
        }
        let step: Int64
        if p > 1 {
            let t = pow(10.0, Double(p - 1))
            step = Int64(round(Double(ds) / t) * t)
        } else {
            step = 1
        }
        let zero = valueRange.min / step * step
        for i in 0...n {
            values.append(zero + i * step)
        }

        self.valueRange = ValueRange(min: min(valueRange.min, zero), max: max(valueRange.max, values.last!))
        self.axisValues = values
    }
}

public struct StaticDrawingValuesCalculation: DrawingValuesCalculation {
    public let valueRange: ValueRange

    public func drawingValues(plots: [Chart.Plot], indexRange: TimeIndexRange) -> DrawingValuesCalculationResult {
        return DrawingValuesCalculationResult(valueRange: valueRange)
    }
}

public struct FullDrawingValuesCalculation: DrawingValuesCalculation {
    public func drawingValues(plots: [Chart.Plot], indexRange: TimeIndexRange) -> DrawingValuesCalculationResult {
        return DrawingValuesCalculationResult(valueRange: ValueRange(ranges: plots.map { $0.valueRange }))
    }
}

public struct SelectedDrawingValuesCalculation: DrawingValuesCalculation {
    public func drawingValues(plots: [Chart.Plot], indexRange: TimeIndexRange) -> DrawingValuesCalculationResult {
        let ranges = plots.map { $0.valueRange(indexRange: indexRange) }
        return DrawingValuesCalculationResult(valueRange: ValueRange(ranges: ranges))
    }
}

