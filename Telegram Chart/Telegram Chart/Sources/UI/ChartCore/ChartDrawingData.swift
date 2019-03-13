//
// Created by Vadim on 2019-03-13.
// Copyright (c) 2019 Vadim Belotitskiy. All rights reserved.
//

import UIKit

public class DrawingChart {

    public let timestamps: [Int64]
    public let timeRange: TimeRange
    public let plots: [Chart.Plot]

    public init(timestamps: [Int64], timeRange: TimeRange, plots: [Chart.Plot]) {
        self.timestamps = timestamps
        self.timeRange = timeRange
        self.plots = plots
    }

    public private(set) lazy var valueRange: ValueRange = {
        return ValueRange(ranges: plots.map { $0.valueRange } )
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
}
