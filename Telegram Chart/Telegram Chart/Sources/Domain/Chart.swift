//
// Created by Vadim on 2019-03-10.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

// TODO: add validation
public class Chart {

    // TODO: create types for all data
    public typealias Time = Int64
    public typealias Value = Int64

    public let plots: [Plot]
    public let timestamps: [Chart.Time]
    public let chartType: ChartType

    public init(timestamps: [Int64], plots: [Plot], chartType: ChartType) {
        self.timestamps = timestamps
        self.plots = plots
        self.chartType = chartType
    }

    public private(set) lazy var timeRange: TimeRange = {
        guard let min = timestamps.first,
              let max = timestamps.last else {
            fatalError("Invalid chart")
        }
        return TimeRange(min: min, max: max)
    }()

    // TODO: replace type with class?
    public class Plot {
        public typealias Identifier = String

        public let identifier: Identifier
        public let name: String
        public let color: UIColor
        public let values: [Chart.Value]
        public let type: PlotType

        public init(
            identifier: String,
            name: String,
            color: UIColor,
            values: [Int64],
            type: PlotType) {
            
            self.identifier = identifier
            self.name = name
            self.color = color
            self.values = values
            self.type = type
        }

        // TODO: is needed or optimize
        public private(set) lazy var valueRange: ValueRange = {
            return ValueRange(values: values)
        }()

        public func valueRange(indexRange: TimeIndexRange) -> ValueRange {
            return ValueRange(values: values, indexRange: indexRange)
        }
    }
}

public extension Chart.Value {
    static let zero = Chart.Value(0)
}

public enum ChartType {
    case simple, yScaled, stacked, percentageStacked
}

public enum PlotType {
    case line, area, bar
}

public struct ValueRange: Equatable {
    public var min: Chart.Value
    public var max: Chart.Value
    public var size: Chart.Value

    public static let percentage = ValueRange(min: 0, max: 100)

    public init(min: Chart.Value, max: Chart.Value) {
        self.min = min
        self.max = max
        size = max - min
    }

    public init(value: Chart.Value) {
        min = value
        max = value
        size = 0
    }

    fileprivate init(values: [Chart.Value], indexRange: TimeIndexRange? = nil) {
        guard values.count > 1 else {
            fatalError("Invalid plot")
        }

        let r = indexRange ?? TimeIndexRange(length: values.count)
        min = values[r.startIdx]
        max = values[r.startIdx]

        var i = r.startIdx + 1
        while i <= r.endIdx {
            let v = values[i]
            if v < min {
                min = v
            } else if v > max {
                max = v
            }
            i += 1
        }
        size = max - min
    }

    init(ranges: [ValueRange]) {
        min = ranges[0].min
        max = ranges[0].max

        for i in 1..<ranges.count {
            let r = ranges[i]
            if r.min < min {
                min = r.min
            } else if r.max > max {
                max = r.max
            }
        }
        size = max - min
    }
}

public struct TimeRange: Equatable {
    public let min: Chart.Time
    public let max: Chart.Time
    public let size: Chart.Time

    public init(min: Chart.Time, max: Chart.Time) {
        self.min = min
        self.max = max
        size = max - min
    }

    public func beforeTimestamp(_ timestamp: Chart.Time) -> TimeRange {
        return TimeRange(min: min, max: timestamp)
    }

    public func afterTimestamp(_ timestamp: Chart.Time) -> TimeRange {
        return TimeRange(min: timestamp, max: max)
    }
}

public struct TimeIndexRange {
    let startIdx: Int
    let length: Int
    let endIdx: Int

    public init(length: Int) {
        self.startIdx = 0
        self.endIdx = startIdx + length - 1
        self.length = length
    }

    public init(timestamps: [Chart.Time], timeRange: TimeRange) {
        var startIdx = 0
        var endIdx = 0

        var i = 0
        while i < timestamps.count - 1 {
            if timestamps[i] == timeRange.min || (timestamps[i] < timeRange.min && timeRange.min < timestamps[i + 1]) {
                startIdx = i
                break
            }
            i += 1
        }

        i = timestamps.count - 1
        while i > 0 {
            if timestamps[i] == timeRange.max || (timestamps[i - 1] < timeRange.max && timeRange.max < timestamps[i]) {
                endIdx = i
                break
            }
            i -= 1
        }

        self.startIdx = startIdx
        self.endIdx = endIdx
        self.length = endIdx - startIdx + 1
    }
}
