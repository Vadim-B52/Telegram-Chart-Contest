//
// Created by Vadim on 2019-03-10.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

// TODO: add validation
public class Chart {

    public let plots: [Plot]
    public let timestamps: [Int64]

    public init(timestamps: [Int64], plots: [Plot]) {
        self.timestamps = timestamps
        self.plots = plots
    }

    public private(set) lazy var timeRange: TimeRange = {
        guard let min = timestamps.first,
              let max = timestamps.last else {
            fatalError("Invalid chart")
        }
        return TimeRange(min: min, max: max)
    }()

    public class Plot {
        public let identifier: String
        public let name: String
        public let color: UIColor
        public let values: [Int64]

        public init(identifier: String,
                         name: String,
                         color: UIColor,
                         values: [Int64]) {
            
            self.identifier = identifier
            self.name = name
            self.color = color
            self.values = values
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

public struct ValueRange {
    public var min: Int64
    public var max: Int64
    public var size: Int64

    public init(min: Int64, max: Int64) {
        self.min = min
        self.max = max
        size = max - min
    }

    public init(value: Int64, idx: Int) {
        min = value
        max = value
        size = 0
    }

    fileprivate init(values: [Int64], indexRange: TimeIndexRange? = nil) {
        guard values.count > 1 else {
            fatalError("Invalid plot")
        }

        let r = indexRange ?? TimeIndexRange(length: values.count)
        min = values[r.startIdx]
        max = values[r.startIdx]

        for i in (r.startIdx + 1)...r.endIdx {
            let v = values[i]
            if v < min {
                min = v
            } else if v > max {
                max = v
            }
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
    public let min: Int64
    public let max: Int64
    public let size: Int64

    public init(min: Int64, max: Int64) {
        self.min = min
        self.max = max
        size = max - min
    }

    public func beforeTimestamp(_ timestamp: Int64) -> TimeRange {
        return TimeRange(min: min, max: timestamp)
    }

    public func afterTimestamp(_ timestamp: Int64) -> TimeRange {
        return TimeRange(min: timestamp, max: max)
    }
}

public struct TimeIndexRange {
    let startIdx: Int
    let length: Int
    var endIdx: Int {
        return startIdx + length - 1
    }

    public init(length: Int) {
        self.startIdx = 0
        self.length = length
    }

    public init(timestamps: [Int64], timeRange: TimeRange) {
        var startIdx = 0
        var length = 0

        for i in 0..<timestamps.count - 1 {
            if timestamps[i] == timeRange.min || (timestamps[i] < timeRange.min && timeRange.min < timestamps[i + 1]) {
                startIdx = i
                length = 1
                break
            }
        }
        for i in startIdx..<timestamps.count - 1 {
            length += 1
            if timestamps[i] == timeRange.max || (timestamps[i] < timeRange.max && timeRange.max < timestamps[i + 1]) {
                break
            }
        }

        self.startIdx = startIdx
        self.length = length
    }
}
