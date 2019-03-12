//
// Created by Vadim on 2019-03-13.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import Foundation

public class PlotDrawingData {

    public let plot: Chart.Plot

    public init(plot: Chart.Plot) {
        self.plot = plot
    }

    public private(set) lazy var ranges: (timeRange: TimeRange, valueRange: ValueRange)? = {
        let values = plot.values
        guard values.count > 1 else {
            return nil
        }   
        var r = ValueRange(value: values[0], idx: 0)
        for i in 1..<values.count {
            let v = values[i]
            if v < r.min {
                r.min = v
                r.minIdx = i
            } else if v > r.max {
                r.max = v
                r.maxIdx = i
            }
        }
        r.size = r.max - r.min
        return (TimeRange(min: plot.timestamps.first!, max: plot.timestamps.last!), r)
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

    public init?(ranges: [ValueRange]) {
        guard !ranges.isEmpty else {
            return nil
        }
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

    init(min: Int64, max: Int64) {
        self.min = min
        self.max = max
        size = max - min
    }
}
