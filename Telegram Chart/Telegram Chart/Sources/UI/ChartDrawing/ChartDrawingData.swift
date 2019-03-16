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

    public func closestIdxTo(timestamp: Int64) -> Int {
        if timestamp <= selectedTimeRange.min {
            return timeIndexRange.startIdx
        }
        if timestamp >= selectedTimeRange.max {
            return timeIndexRange.endIdx
        }
        var low = timeIndexRange.startIdx
        var high = timeIndexRange.endIdx
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
