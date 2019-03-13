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

        public private(set) lazy var valueRange: ValueRange = {
            return ValueRange(plot: self)
        }()
    }
}

public struct ValueRange {
    public fileprivate(set) var min: Int64
    public fileprivate(set) var max: Int64
    public fileprivate(set) var size: Int64
    public fileprivate(set) var minIdx: Int
    public fileprivate(set) var maxIdx: Int

    fileprivate init(value: Int64, idx: Int) {
        min = value
        max = value
        size = 0
        minIdx = idx
        maxIdx = idx
    }

    fileprivate init(plot: Chart.Plot) {
        let values = plot.values
        guard values.count > 1 else {
            fatalError("Invalid plot")
        }

        min = values[0]
        max = values[0]
        minIdx = 0
        maxIdx = 0

        for i in 1..<values.count {
            let v = values[i]
            if v < min {
                min = v
                minIdx = i
            } else if v > max {
                max = v
                maxIdx = i
            }
        }
        size = max - min
    }

    init(ranges: [ValueRange]) {
        min = ranges[0].min
        max = ranges[0].max
        minIdx = ranges[0].minIdx
        maxIdx = ranges[0].maxIdx

        for i in 1..<ranges.count {
            let r = ranges[i]
            if r.min < min {
                min = r.min
                minIdx = r.minIdx
            } else if r.max > max {
                max = r.max
                maxIdx = r.maxIdx
            }
        }
        size = max - min
    }
}

public struct TimeRange {
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
