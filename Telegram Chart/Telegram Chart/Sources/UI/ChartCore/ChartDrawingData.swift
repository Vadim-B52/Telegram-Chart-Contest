//
// Created by Vadim on 2019-03-13.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import Foundation

public class DrawingChart {

    public let timestamps: [Int64]
    public let plots: [Chart.Plot]

    public init(timestamps: [Int64], plots: [Chart.Plot]) {
        self.timestamps = timestamps
        self.plots = plots
    }

    public private(set) lazy var timeRange: TimeRange = {
        guard let min = timestamps.first,
              let max = timestamps.last else {
            fatalError("Invalid chart to display")
        }
        return TimeRange(min: min, max: max)
    }()

    public private(set) lazy var valueRange: ValueRange = {
        return ValueRange(ranges: plots.map { ValueRange(plot: $0) } )
    }()
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

    fileprivate init(ranges: [ValueRange]) {
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

    fileprivate init(min: Int64, max: Int64) {
        self.min = min
        self.max = max
        size = max - min
    }
}
